class_name GitIgnore

# Written by gemini-2.5-pro-exp-03-25

var _rules: Array[Dictionary] = [] # Stores parsed rule dictionaries, now with compiled RegEx objects

# --- Regex Conversion Helpers ---

# Helper to escape regex meta-characters for manual construction.
func _escape_regex_meta_characters(text_char: String) -> String:
	# Characters that have special meaning in regex and need escaping.
	# Note: '/' is not escaped here as it's used as a path separator and handled by pattern logic.
	# '*' and '?' are handled by _convert_segment_to_regex_no_globstar itself.
	var chars_to_escape: String = ".+()[]{}|^$\\"
	if chars_to_escape.contains(text_char):
		return "\\" + text_char
	return text_char

# Converts a non-globstar segment of a gitignore pattern to a regex string part.
# Escapes regex metacharacters and translates '*' and '?'.
func _convert_segment_to_regex_no_globstar(segment_str: String) -> String:
	var re_segment: String = ""
	for char_idx in range(segment_str.length()):
		var ch: String = segment_str[char_idx]
		if ch == '*':
			re_segment += "[^/]*" # Matches zero or more non-slash characters
		elif ch == '?':
			re_segment += "[^/]"   # Matches one non-slash character
		# TODO: Full character class support (e.g., [a-z], [!abc]) could be added here if needed.
		# For now, other characters are escaped.
		else:
			# Use the manual escape function
			re_segment += _escape_regex_meta_characters(ch)
	return re_segment

# Converts a full gitignore pattern line into a complete regex string.
func _gitignore_rule_to_regex_string(pattern_line: String, is_dir_only_from_trailing_slash: bool, original_raw_pattern_for_suffix_logic: String) -> String:
	var p: String = pattern_line # The pattern to process (e.g., "*.log", "/build/", "**/temp")
	#var original_raw_pattern_for_suffix_logic: String = arguments[2] # Expecting raw_line_unstripped passed as third arg

	# Handle special full-line globstar cases first for clarity
	if p == "**":
		return ".*$" # Matches any sequence of characters (files/dirs at any depth)
	if p == "/**": 
		return "^.*$" # Anchored, matches everything under root

	var is_explicitly_anchored: bool = p.begins_with("/")
	if is_explicitly_anchored:
		p = p.substr(1) # Remove leading slash for processing, it's handled by anchoring prefix

	var starts_with_globstar_prefix: bool = p.begins_with("**/")
	if starts_with_globstar_prefix:
		p = p.substr(3) # Remove "**/"; anchoring will be handled by prefix logic
	
	var ends_with_globstar_suffix: bool = false
	# Check for "/**" suffix, but avoid simple "**" becoming empty string if p was "**"
	# And ensure p isn't empty before trying to remove "/**"
	if p.ends_with("/**") and p != "**": 
		ends_with_globstar_suffix = true
		p = p.left(p.length() - 3) # Remove "/**"

	var regex_body: String = ""
	# Split by "/**/" to handle constructs like "a/**/b"
	var components: PackedStringArray = p.split("/**/", false) 

	for i in range(components.size()):
		regex_body += _convert_segment_to_regex_no_globstar(components[i])
		if i < components.size() - 1: # If there was a "/**/" separator
			# "a/**/b" matches "a/b", "a/x/b", "a/x/y/b".
			# This part represents the "/**/" -> a slash, then zero or more "dir/" segments, then the content of b.
			# The regex part for /**/ can be simplified to match / followed by anything until the next pattern segment, or end.
			# A robust /**/ that matches zero or more directories is tricky.
			# Git: "a slash followed by two consecutive asterisks then a slash matches zero or more directories."
			# So, a/**/b translates to regex(a) + (/(?:[^/]+/)*)? + regex(b)
			# My previous version was: regex_body += "/" + "(?:(?:[^/]+)/)*?"
			# This should be more like: (?:/(?:.+/)*)? if it needs to match full directory names.
			# For simplicity and covering `a/b` and `a/x/b` and `a/x/y/b`:
			# Regex for a: (a_regex)
			# Regex for b: (b_regex)
			# Pattern a/**/b: (a_regex)(?:/(?:[^/]+/)*?)?(b_regex) -> needs slashes carefully placed
			# Corrected approach for "/**/":
			regex_body += "(?:(?:/.+)*?/|/)" # Matches / or /dir1/dir2/.../ (non-greedy)
			# This ensures the slash separating 'a' from the globstar part and the globstar part from 'b' is handled correctly.
			# If components[i] is empty (e.g. pattern like "/**/foo"), this still adds the globstar match.

	var final_regex_str: String = ""

	# Determine prefix based on anchoring rules
	if is_explicitly_anchored:
		final_regex_str += "^"
	elif starts_with_globstar_prefix: # Original was "**/something"
		final_regex_str += "(?:^|.*/)" # Match current dir or any parent dir + slash
	elif p.contains("/"): # e.g., "foo/bar" (no leading slash) -> considered anchored to .gitignore location
		final_regex_str += "^"
	else: # Simple pattern like "*.log" or "build" (no slashes, not starting **/) -> match anywhere
		final_regex_str += "(?:^|.*/)"

	final_regex_str += regex_body

	if ends_with_globstar_suffix: # Original was "something/**"
		# Ensures it matches the directory itself and anything underneath.
		# Example: "foo/**" becomes regex for "foo" + "(/.*)?"
		# If regex_body is empty (original was "/**", handled above), this won't apply.
		if not regex_body.ends_with("/") and not regex_body.is_empty():
			final_regex_str += "/" # Add a slash if pattern was like "foo" before "/**"
		final_regex_str += ".*" # Match any char sequence (files and dirs within)

	# Handle directory-only patterns (from original trailing slash) and end-of-string anchor
	if is_dir_only_from_trailing_slash:
		# Pattern was "foo/" (is_dir_only_from_trailing_slash=true, pattern_line="foo"). Matches "foo" or "foo/anything".
		# final_regex_str already contains (prefix)regex_body, e.g. (?:^|.*/)foo or ^foo
		# We need to ensure it can match the directory itself or anything underneath.
		final_regex_str += "(?:/.*)?$"
	else:
		# Not a "foo/" type rule. Could be "foo" or "*.log" or "foo/bar".
		# original_raw_pattern_for_suffix_logic is the line from the gitignore file, before negation/dir slash stripping.
		var temp_check_pattern: String = original_raw_pattern_for_suffix_logic
		if temp_check_pattern.begins_with("!"): # Use the pattern part after "!"
			temp_check_pattern = temp_check_pattern.substr(1)
		# And remove trailing slash if it was for is_dir_only, as pattern_line wouldn't have it
		# This 'else' block means is_dir_only_from_trailing_slash is false, so original didn't end with a simple slash
		
		if not pattern_line.contains("/") and \
		   not pattern_line.contains("*") and \
		   not pattern_line.contains("?") and \
		   not pattern_line.contains("[") and \
		   not pattern_line.is_empty():
			# It's a simple name like "build" or "foo" (pattern_line is the core, e.g., "foo").
			# This should match the directory and its contents.
			# final_regex_str already contains (prefix)regex_body, e.g. (?:^|.*/)foo
			final_regex_str += "(?:/.*)?$" # Match "foo" or "foo/anything"
		else:
			# It's a glob like "*.log", or an anchored path like "foo/bar", or contains complex parts.
			# These match files or specific paths more precisely.
			final_regex_str += "$" # Must match the end of the string exactly for these.

	return final_regex_str

# --- Main Class Logic ---

func _parse_contents(contents: String) -> void:
	_rules.clear()
	var lines_arr: PackedStringArray = contents.split("\n")
	
	for raw_line_unstripped in lines_arr:
		var line: String = raw_line_unstripped.strip_edges()
		
		# Look for and ignore comments
		if line.is_empty() or line.begins_with("#"):
			continue

		var is_negation: bool = false
		if line.begins_with("!"):
			is_negation = true
			line = line.substr(1)
			if line.is_empty(): continue # Invalid: "!" alone

		var is_dir_only_rule: bool = false
		var core_pattern_for_regex: String = line

		# A simple trailing slash like "foo/" makes it a directory-only rule.
		# This does not apply to slashes that are part of globstar constructs like "/**/" or "/**".
		# Those are handled by the globstar logic within _gitignore_rule_to_regex_string.
		if line.ends_with("/") and not line.ends_with("/**") and not (line.contains("/**/") and line.ends_with("/")):
			is_dir_only_rule = true
			# Strip the trailing slash for core_pattern_for_regex processing.
			# _gitignore_rule_to_regex_string will reconstruct dir matching logic based on is_dir_only_rule.
			core_pattern_for_regex = core_pattern_for_regex.left(core_pattern_for_regex.length() - 1)
			# Prevent empty pattern if original was just "/"
			if core_pattern_for_regex.is_empty() and line == "/":
				# This case is tricky. A single "/" is a root anchor for directory.
				# Let _gitignore_rule_to_regex_string handle "/" with is_dir_only_rule=true.
				# It might become an empty `p` if it was just "/", which then needs careful prefixing.
				# For now, let's assume _gitignore_rule_to_regex_string correctly handles an empty `core_pattern_for_regex`
				# when `is_explicitly_anchored` is true.
				# If line was just "/", core_pattern_for_regex becomes "", is_dir_only_rule=true.
				# _gitignore_rule_to_regex_string("", true) with explicit anchor logic.
				pass


		var regex_string: String = _gitignore_rule_to_regex_string(core_pattern_for_regex, is_dir_only_rule, raw_line_unstripped)
		
		var regex: RegEx = RegEx.new()
		var err: Error = regex.compile(regex_string)
		if err != OK:
			printerr("GitIgnore: Failed to compile regex: '%s' (from pattern '%s'). Error code: %s" % [regex_string, line, err])
			continue # Skip this rule if regex compilation fails
		
		_rules.append({
			"regex_object": regex,
			"is_negation": is_negation,
			"original_line_for_debug": raw_line_unstripped 
		})

func _path_matches_rule(path_to_check: String, rule: Dictionary) -> bool:
	var regex: RegEx = rule.regex_object as RegEx
	if regex == null: # Should not happen if parse_contents skips failed compiles
		printerr("GitIgnore: Invalid RegEx object in rule: %s" % rule.original_line_for_debug)
		return false
	var match_result: RegExMatch = regex.search(path_to_check)
	return match_result != null

func _is_path_definitively_ignored(path_to_evaluate: String) -> bool:
	var is_ignored_status: bool = false # Default to not ignored (i.e., included)
	for rule in _rules:
		if _path_matches_rule(path_to_evaluate, rule):
			# Last matching rule wins. If it's a negation, path is included (not ignored).
			# If it's an ignore rule, path is ignored.
			is_ignored_status = not rule.is_negation 
	return is_ignored_status

func _init(contents: String) -> void:
	_parse_contents(contents)

func append_gitignore_for_subdirectory(subdirectory_path: String, contents: String) -> void:
	var normalized_subdir_path: String = subdirectory_path.replace("\\", "/")
	if not normalized_subdir_path.is_empty() and not normalized_subdir_path.ends_with("/"):
		normalized_subdir_path += "/"

	var lines_arr: PackedStringArray = contents.split("\n")
	
	for raw_line_unstripped_from_sub in lines_arr:
		var line_from_sub_gitignore: String = raw_line_unstripped_from_sub.strip_edges()
		
		if line_from_sub_gitignore.is_empty() or line_from_sub_gitignore.begins_with("#"):
			continue

		var is_negation: bool = false
		var pattern_part_from_sub: String = line_from_sub_gitignore
		if pattern_part_from_sub.begins_with("!"):
			is_negation = true
			pattern_part_from_sub = pattern_part_from_sub.substr(1)
			if pattern_part_from_sub.is_empty(): continue

		var effective_pattern: String
		if pattern_part_from_sub.begins_with("/"):
			effective_pattern = normalized_subdir_path + pattern_part_from_sub.substr(1)
		else:
			effective_pattern = normalized_subdir_path + pattern_part_from_sub
		
		var final_original_line_for_debug_and_suffix_logic: String = effective_pattern
		if is_negation:
			final_original_line_for_debug_and_suffix_logic = "!" + effective_pattern

		var is_dir_only_rule_for_effective: bool = false
		var core_pattern_for_regex_from_effective: String = effective_pattern

		# Determine if the *effective* pattern is directory-only
		if effective_pattern.ends_with("/") and \
		   not effective_pattern.ends_with("/**") and \
		   not (effective_pattern.contains("/**/") and effective_pattern.ends_with("/")):
			is_dir_only_rule_for_effective = true
			core_pattern_for_regex_from_effective = core_pattern_for_regex_from_effective.left(core_pattern_for_regex_from_effective.length() - 1)
			# Handle cases like `normalized_subdir_path` being empty and `pattern_part_from_sub` being just "/"
			# resulting in `effective_pattern` being "/", so `core_pattern_for_regex_from_effective` becomes "".
			if core_pattern_for_regex_from_effective.is_empty() and effective_pattern == "/":
				pass # _gitignore_rule_to_regex_string handles empty core pattern if anchored & dir_only

		var regex_string: String = _gitignore_rule_to_regex_string(
			core_pattern_for_regex_from_effective, 
			is_dir_only_rule_for_effective, 
			final_original_line_for_debug_and_suffix_logic # Used for suffix decisions in _gitignore_rule_to_regex_string
		)
		
		var regex: RegEx = RegEx.new()
		var err: Error = regex.compile(regex_string)
		if err != OK:
			printerr("GitIgnore (subdir '%s'): Failed to compile regex: '%s' (from effective pattern '%s', original line in sub-gitignore '%s'). Error code: %s" % [normalized_subdir_path, regex_string, effective_pattern, line_from_sub_gitignore, err])
			continue
		
		_rules.append({
			"regex_object": regex,
			"is_negation": is_negation, # Negation based on original line from sub_gitignore
			"original_line_for_debug": final_original_line_for_debug_and_suffix_logic # Store the root-relative effective pattern
		})

# --- Static Helper for File Reading ---
static func _read_file_contents(file_path: String) -> String:
	if not FileAccess.file_exists(file_path):
		return ""
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("GitIgnore: Error opening file for read: %s (Error: %s)" % [file_path, FileAccess.get_open_error()])
		return ""
	var content := file.get_as_text()
	# FileAccess.get_as_text() closes the file.
	return content

# --- Instance Helper for Recursive Gitignore Collection ---
func _collect_and_append_nested_gitignores(current_dir_abs: String, project_root_abs: String, file_name: String = ".gitignore") -> void:
	var da := DirAccess.open(current_dir_abs)
	if da == null:
		printerr("GitIgnore: Cannot open directory for scanning: %s (Error: %s)" % [current_dir_abs, DirAccess.get_open_error()])
		return

	while true:
		var item_name := da.get_next()
		if item_name.is_empty():
			break # End of directory
		if item_name == "." or item_name == "..":
			continue

		var item_full_path_abs := current_dir_abs.path_join(item_name)
		# Path relative to project_root_abs, without leading slash, for is_included checks
		var item_relative_path_to_root := item_full_path_abs.replace(project_root_abs, "").trim_prefix("/")
		
		if da.current_is_dir():
			# Only recurse if the directory itself is not excluded.
			# The is_included method handles parent directory exclusion logic.
			if self.is_included(item_relative_path_to_root): 
				_collect_and_append_nested_gitignores(item_full_path_abs, project_root_abs)
		elif item_name == file_name:
			# This .gitignore is in current_dir_abs.
			# The "subdirectory_path" for append_gitignore_for_subdirectory
			# is the path of current_dir_abs relative to project_root_abs.
			var relative_container_dir_path := current_dir_abs.replace(project_root_abs, "").trim_prefix("/")
			
			# Ensure this isn't the root .gitignore being re-added.
			# The root .gitignore corresponds to an empty relative_container_dir_path.
			if not relative_container_dir_path.is_empty():
				var nested_gitignore_contents := GitIgnore._read_file_contents(item_full_path_abs)
				if not nested_gitignore_contents.is_empty():
					self.append_gitignore_for_subdirectory(relative_container_dir_path, nested_gitignore_contents)

# Returns false if the target path is ignored.
func is_included(path: String) -> bool:
	# Normalize path: use forward slashes, remove leading slash if present.
	var file_path: String = path.replace("\\", "/") 
	if file_path.begins_with("/"):
		file_path = file_path.substr(1)
	
	# For matching purposes, internal logic expects paths without trailing slashes unless it's the root "/".
	# However, gitignore rules for directories often end with '/', and paths to check might too.
	# The regex generated for dir rules (e.g., "foo/") is `foo(?:/.*)?$`, which handles `foo` and `foo/anything`.
	# So, if file_path is "foo/", it should still match correctly.
	# Let's remove trailing slash from file_path *only if it's not just root "/"* to be consistent.
	if file_path.ends_with("/") and file_path.length() > 1:
		file_path = file_path.trim_suffix("/")

	var is_target_path_ignored: bool = _is_path_definitively_ignored(file_path)
	
	# Handle parent directory exclusion: 
	# "It is not possible to re-include a file if a parent directory of that file is excluded."
	if not is_target_path_ignored: # If the file itself IS NOT ignored by its own rule set...
		var current_parent_path: String = file_path
		while current_parent_path.contains("/"): # Iterate through parent directories
			current_parent_path = current_parent_path.get_base_dir()
			if current_parent_path.is_empty() or current_parent_path == ".": # Stop if we reach root or an invalid state
				break 
			
			if _is_path_definitively_ignored(current_parent_path): # If any ancestor directory IS IGNORED...
				return false # ...then this path is ultimately EXCLUDED (not included), regardless of its own rules.
	
	return not is_target_path_ignored # True if not ignored (included), False if ignored.


# --- Static Factory Function ---
static func load_from_directory(p_project_root_path: String, file_name: String = ".gitignore") -> GitIgnore:
	if p_project_root_path.is_empty():
		printerr("GitIgnore.load_from_directory: project_root_path cannot be empty.")
		return null

	var project_root_path_clean := p_project_root_path.replace("\\", "/")
	# Normalize path: remove trailing slash if it's not the root "/" itself.
	if project_root_path_clean.ends_with("/") and project_root_path_clean.length() > 1:
		project_root_path_clean = project_root_path_clean.trim_suffix("/")

	var root_gitignore_file_path := project_root_path_clean.path_join(file_name)
	var root_contents := GitIgnore._read_file_contents(root_gitignore_file_path)
	
	var gitignore_obj := GitIgnore.new(root_contents)
	if gitignore_obj == null: 
		printerr("GitIgnore.load_from_directory: Failed to create GitIgnore object with root " + file_name + " content.")
		return null

	# Start recursive scan from the project root.
	# _collect_and_append_nested_gitignores will find .gitignores in subdirectories.
	gitignore_obj._collect_and_append_nested_gitignores(project_root_path_clean, project_root_path_clean, file_name)
	
	return gitignore_obj

func _to_string() -> String:
	var output_parts: Array[String] = []
	output_parts.append("GitIgnore object:")
	output_parts.append("  Number of rules: %s" % _rules.size())

	if _rules.is_empty():
		output_parts.append("  No rules loaded.")
	else:
		var preview_count = min(5, _rules.size())
		output_parts.append("  First %s rule(s) (original lines):" % preview_count)
		for i in range(preview_count):
			var rule: Dictionary = _rules[i]
			var original_line: String = rule.get("original_line_for_debug", "<unknown original line>")
			var is_negation_val: bool = rule.get("is_negation", false) # Explicitly bool
			# We show the effective original line which might already include negation if it was parsed that way
			var display_line := original_line
			# The original_line_for_debug *should* already contain the '!' if it was a negation rule.
			# This logic is mostly a safeguard or for clarity if original_line_for_debug was stored differently.
			if is_negation_val and not original_line.begins_with("!"):
				display_line = "!" + original_line
			
			output_parts.append("    - '%s'" % display_line)
		
		if _rules.size() > preview_count:
			output_parts.append("    ... and %s more rule(s)." % (_rules.size() - preview_count))
	
	return "\n".join(output_parts)
