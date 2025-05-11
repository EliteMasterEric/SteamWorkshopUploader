class_name TestGitIgnore

static func run_all_gitignore_tests() -> void:
	var test_suites = [
		{
			"name": "Basic Matching, Comments, Blank Lines",
			"gitignore_content": """
# This is a comment

*.log
build/

# Another comment
.DS_Store
""",
			"checks": [
				{"path": "file.txt", "expected_included": true, "reason": "Should not be matched"},
				{"path": "app.log", "expected_included": false, "reason": "Ignored by *.log"},
				{"path": "test/deep/another.log", "expected_included": false, "reason": "Ignored by *.log (deep)"},
				{"path": "build/output.bin", "expected_included": false, "reason": "Ignored by build/ (file in dir)"},
				{"path": "build", "expected_included": false, "reason": "Ignored by build/ (dir itself)"},
				{"path": "src/build/old.file", "expected_included": false, "reason": "Ignored by 'build/' (matches 'build' dir anywhere, including 'src/build')"},
				{"path": ".DS_Store", "expected_included": false, "reason": "Ignored by .DS_Store"},
				{"path": "foo/.DS_Store", "expected_included": false, "reason": "Ignored by .DS_Store (deep)"}
			]
		},
		{
			"name": "Negation and Precedence",
			"gitignore_content": """
*.log
!important.log

# Later rule overrides
config.txt
!config.txt
final_config.txt
""",
			"checks": [
				{"path": "app.log", "expected_included": false, "reason": "Ignored by *.log"},
				{"path": "important.log", "expected_included": true, "reason": "Re-included by !important.log"},
				{"path": "data/important.log", "expected_included": true, "reason": "Re-included by !important.log (deep)"},
				{"path": "another.log", "expected_included": false, "reason": "Still ignored by *.log"},
				{"path": "config.txt", "expected_included": true, "reason": "Negated by !config.txt after initial ignore"},
				{"path": "final_config.txt", "expected_included": false, "reason": "Ignored by final_config.txt (last rule)"}
			]
		},
		{
			"name": "Directory Patterns and Root Anchoring with RegEx",
			"gitignore_content": """
/root_only_dir/

non_root_dir/

*.tmp
!non_root_dir/keep.tmp

/specific_file.txt

# Test for exact file match (RegEx should handle this better)
/exact_match_file
""",
			"checks": [
				{"path": "root_only_dir/file.txt", "expected_included": false, "reason": "Ignored by /root_only_dir/"},
				{"path": "root_only_dir", "expected_included": false, "reason": "Dir ignored by /root_only_dir/"},
				{"path": "another/root_only_dir/file.txt", "expected_included": true, "reason": "/root_only_dir/ is root anchored"},
				{"path": "non_root_dir/file.txt", "expected_included": false, "reason": "Ignored by non_root_dir/"},
				{"path": "non_root_dir", "expected_included": false, "reason": "non_root_dir/ dir matches at any level"},
				{"path": "level1/non_root_dir/deep_file.txt", "expected_included": false, "reason": "non_root_dir/ matches at any level"},
				{"path": "level1/non_root_dir", "expected_included": false, "reason": "non_root_dir/ dir matches at any level"},
				{"path": "non_root_dir/keep.tmp", "expected_included": false, "reason": "Cannot re-include, parent 'non_root_dir/' is ignored by 'non_root_dir/' rule"},
				{"path": "data/archive.tmp", "expected_included": false, "reason": "Ignored by *.tmp"},
				{"path": "specific_file.txt", "expected_included": false, "reason": "Ignored by /specific_file.txt (root anchored)"},
				{"path": "src/specific_file.txt", "expected_included": true, "reason": "/specific_file.txt is root anchored"},
				{"path": "exact_match_file", "expected_included": false, "reason": "Should be ignored by /exact_match_file (exact path)"},
				{"path": "exact_match_file.txt", "expected_included": true, "reason": "Should NOT be ignored by /exact_match_file (different file)"}
			]
		},
		{
			"name": "Parent Directory Exclusion Overriding Negation",
			"gitignore_content": """
out/
!out/important_file.txt

/root_out/
!/root_out/important_file.txt
""",
			"checks": [
				{"path": "out/some_file.data", "expected_included": false, "reason": "Ignored by out/"},
				{"path": "out/important_file.txt", "expected_included": false, "reason": "Cannot re-include, parent 'out/' is ignored"},
				{"path": "root_out/another.data", "expected_included": false, "reason": "Ignored by /root_out/"},
				{"path": "root_out/important_file.txt", "expected_included": false, "reason": "Cannot re-include, parent '/root_out/' is ignored"}
			]
		},
		{
			"name": "Patterns with Internal Slashes",
			"gitignore_content": """
src/include/
!src/include/public.h

libs/*.dll
""",
			"checks": [
				{"path": "src/include/internal.h", "expected_included": false, "reason": "Ignored by src/include/"},
				{"path": "src/include/public.h", "expected_included": false, "reason": "Cannot re-include, parent 'src/include/' is ignored by 'src/include/' rule"},
				{"path": "src/another/file.txt", "expected_included": true, "reason": "Not matched by src/include/"},
				{"path": "libs/mylib.dll", "expected_included": false, "reason": "Ignored by libs/*.dll (anchored due to /)"},
				{"path": "other/libs/another.dll", "expected_included": true, "reason": "libs/*.dll is effectively root-anchored due to slash"}
			]
		},
		{
			"name": "Globstar (**) Patterns",
			"gitignore_content": """
# Leading globstar
**/temp.txt
**/cache/

# Trailing globstar
logs/**
/docs/**

# Middle globstar
src/**/models/*.glb
assets/**/data.json

# Standalone globstar
**
!keep_this.file

# Globstar with directory
python_modules/**/
""",
			"checks": [
				{"path": "temp.txt", "expected_included": false, "reason": "**/temp.txt matches at root"},
				{"path": "sub/temp.txt", "expected_included": false, "reason": "**/temp.txt matches in subdir"},
				{"path": "deep/down/temp.txt", "expected_included": false, "reason": "**/temp.txt matches deep"},
				{"path": "cache/file", "expected_included": false, "reason": "**/cache/ matches dir at root"},
				{"path": "old/cache/file", "expected_included": false, "reason": "**/cache/ matches dir in subdir"},
				{"path": "logs/today.log", "expected_included": false, "reason": "logs/** includes files in logs/"},
				{"path": "logs/archived/old.zip", "expected_included": false, "reason": "logs/** includes files in logs/archived/"},
				{"path": "not_logs/today.log", "expected_included": false, "reason": "Not matched by 'logs/**' (anchored), but matched by later '**' rule"},
				{"path": "docs/feature/readme.md", "expected_included": false, "reason": "/docs/** (anchored)"},
				{"path": "mydocs/feature/readme.md", "expected_included": false, "reason": "Not matched by '/docs/**', but matched by later '**' rule"},
				{"path": "src/components/player/models/player.glb", "expected_included": false, "reason": "src/**/models/*.glb"},
				{"path": "src/old_models/enemy.glb", "expected_included": false, "reason": "Not matched by 'src/**/models/*.glb', but matched by later '**' rule"},
				{"path": "src/models/ship.glb", "expected_included": false, "reason": "src/**/models/*.glb (globstar matches zero dirs)"},
				{"path": "assets/level1/data.json", "expected_included": false, "reason": "assets/**/data.json"},
				{"path": "assets/data.json", "expected_included": false, "reason": "assets/**/data.json (zero dirs)"},
				{"path": "random_file.xyz", "expected_included": false, "reason": "** catch-all"},
				{"path": "keep_this.file", "expected_included": true, "reason": "!negation after **"},
				{"path": "python_modules/module_a/init.py", "expected_included": false, "reason": "python_modules/**/ matches content of subdirs"},
				{"path": "python_modules/some_file.pyc", "expected_included": false, "reason": "Matched by 'python_modules/**/' (or fallback to later '**' rule)"}
			]
		},
		{
			"name": "Tricky cases and edge patterns with RegEx",
			"gitignore_content": """
foo
!foo/bar
foo/bar/baz

# Trailing spaces test (Git trims them, so should we in parsing)
   *.o   

# Slash at start of pattern
/rooted_file.txt

# Empty or invalid lines should be ignored by parser

! 
   #

final_rule
""",
			"checks": [
				{"path": "foo", "expected_included": false, "reason": "Ignored by 'foo' rule"},
				{"path": "foo/other.txt", "expected_included": false, "reason": "Ignored by 'foo' (parent dir rule applies as 'foo' matches dir and contents)"},
				{"path": "foo/bar", "expected_included": false, "reason": "Cannot re-include, parent 'foo' is ignored by 'foo' rule"},
				{"path": "foo/bar/another.txt", "expected_included": false, "reason": "Parent 'foo' is ignored by 'foo' rule, so 'foo/bar/another.txt' is ignored"},
				{"path": "foo/bar/baz", "expected_included": false, "reason": "Ignored by 'foo/bar/baz' (and parent 'foo' also ignored)"},
				{"path": "foo/bar/baz/deep.txt", "expected_included": false, "reason": "Child of ignored 'foo/bar/baz'"},
				{"path": "file.o", "expected_included": false, "reason": "Ignored by '*.o   ' (spaces trimmed)"},
				{"path": "lib/another.o", "expected_included": false, "reason": "Ignored by '*.o   ' (deep, spaces trimmed)"},
				{"path": "rooted_file.txt", "expected_included": false, "reason": "Ignored by /rooted_file.txt"},
				{"path": "sub/rooted_file.txt", "expected_included": true, "reason": "Not matched by /rooted_file.txt (not at root)"},
				{"path": "final_rule", "expected_included": false, "reason": "Matched by final_rule"},
				{"path": "unmatched_file", "expected_included": true, "reason": "No rule matches"},
			]
		},
		{
			"name": "Empty Gitignore File",
			"gitignore_content": "", # Empty content
			"checks": [
				{"path": "file.txt", "expected_included": true, "reason": "No rules, should be included"},
				{"path": "another_file.log", "expected_included": true, "reason": "No rules, should be included"},
				{"path": "dir/some_file.data", "expected_included": true, "reason": "No rules, should be included"},
				{"path": "dir/", "expected_included": true, "reason": "No rules, directory itself should be included"}
			]
		},
		{
			"name": "Subdirectory .gitignore Appending",
			"setup_instructions": { # New key to guide the test execution
				"root_gitignore_content": """
# Root ignore rules
root_ignored_dir/
*.global_tmp
!important_global.global_tmp
docs/
				""",
				"subdirectories": [
					{
						"path": "modules/mod_a",
						"gitignore_content": """
# mod_a specific rules
src/
/dist/
!dist/keep_this.bin
*.local_log
temp_file.txt
# Try to re-include something from root ignored 'docs/' but within this module's path
!docs/important.md 
						"""
					},
					{
						"path": "assets",
						"gitignore_content": """
# Assets specific
raw_files/
!raw_files/image.png 
data.json 
						"""
					}
				]
			},
			"checks": [
				# Root rules behavior
				{"path": "root_ignored_dir/file.txt", "expected_included": false, "reason": "Ignored by root: root_ignored_dir/"},
				{"path": "some_file.global_tmp", "expected_included": false, "reason": "Ignored by root: *.global_tmp"},
				{"path": "important_global.global_tmp", "expected_included": true, "reason": "Re-included by root: !important_global.global_tmp"},
				{"path": "docs/project_readme.txt", "expected_included": false, "reason": "Ignored by root: docs/"},

				# modules/mod_a specific rules
				{"path": "modules/mod_a/src/main.js", "expected_included": false, "reason": "mod_a: src/ (becomes modules/mod_a/src/)"},
				{"path": "modules/mod_a/dist/output.exe", "expected_included": false, "reason": "mod_a: /dist/ (becomes modules/mod_a/dist/)"},
				{"path": "modules/mod_a/dist/keep_this.bin", "expected_included": false, "reason": "mod_a: Parent 'modules/mod_a/dist/' is ignored by effective rule 'modules/mod_a/dist/', so cannot re-include child."},
				{"path": "modules/mod_a/another_file.txt", "expected_included": true, "reason": "mod_a: No rule matches"},
				{"path": "modules/mod_a/file.local_log", "expected_included": false, "reason": "mod_a: *.local_log (becomes modules/mod_a/*.local_log)"},
				
				# Check that mod_a rules don't accidentally affect paths outside their effective scope
				{"path": "src/main.js", "expected_included": true, "reason": "Root: No rule. mod_a rule for src/ is prefixed to modules/mod_a/src/"},
				{"path": "dist/output.exe", "expected_included": true, "reason": "Root: No rule. mod_a rule for /dist/ is prefixed to modules/mod_a/dist/"},
				{"path": "file.local_log", "expected_included": true, "reason": "Root: No rule. mod_a rule for *.local_log is prefixed to modules/mod_a/*.local_log"},

				# Assets specific rules
				{"path": "assets/raw_files/doc.raw", "expected_included": false, "reason": "assets: raw_files/ (becomes assets/raw_files/)"},
				{"path": "assets/raw_files/image.png", "expected_included": false, "reason": "assets: Parent 'assets/raw_files/' is ignored by effective rule 'assets/raw_files/', so cannot re-include child."},
				{"path": "assets/final/image.png", "expected_included": true, "reason": "assets: No rule for final/"},
				{"path": "assets/data.json", "expected_included": false, "reason": "assets: data.json (becomes assets/data.json)"},
				{"path": "data.json", "expected_included": true, "reason": "Root: No rule. assets rule for data.json is prefixed to assets/data.json"},
				
				# Parent directory exclusion: root 'docs/' ignores 'modules/mod_a/docs/'
				{"path": "modules/mod_a/docs/important.md", "expected_included": false, "reason": "Root ignores 'docs/', so 'modules/mod_a/docs/' is ignored. Subdir re-inclusion ineffective due to parent dir exclusion."},

				# Negation interaction
				{"path": "modules/mod_a/important_global.global_tmp", "expected_included": true, "reason": "Root re-includes this specific file. Subdir rules (like *.local_log or effective *.global_tmp) don't override this more specific root negation for the exact path."},
				{"path": "modules/mod_a/another.global_tmp", "expected_included": false, "reason": "Ignored by root '*.global_tmp', not the specific root re-inclusion, and not matched by distinct subdir rules."}
			]
		}
	]

	var total_tests = 0
	var passed_tests = 0

	print("Running GitIgnore Tests (RegEx version) from tests/test_gitignore.gd...")
	print("NOTE: Globstar (**) support is based on common interpretations and may have edge case differences from native git.")

	for suite in test_suites:
		print("\n--- Test Suite: %s ---" % suite.name)
		var gitignore: GitIgnore # Declare gitignore instance here

		if suite.has("setup_instructions"):
			var setup = suite.setup_instructions
			gitignore = GitIgnore.new(setup.root_gitignore_content)
			if setup.has("subdirectories"):
				for sub_info in setup.subdirectories:
					gitignore.append_gitignore_for_subdirectory(sub_info.path, sub_info.gitignore_content)
		elif suite.has("gitignore_content"): # Existing logic
			gitignore = GitIgnore.new(suite.gitignore_content)
		else:
			printerr("Test suite '%s' is missing 'gitignore_content' or 'setup_instructions'." % suite.name)
			continue # Skip this suite

		# For debugging specific suites:
		# if suite.name == "Globstar (**) Patterns":
		# 	 for rule_idx in range(gitignore._rules.size()):
		# 		 var r = gitignore._rules[rule_idx]
		# 		 print("    Rule %d: pattern='%s', regex='%s', negation=%s" % [rule_idx, r.original_line_for_debug, r.regex_object.get_pattern(), r.is_negation])

		for check in suite.checks:
			total_tests += 1
			var path_to_check = check.path
			var expected = check.expected_included
			var reason = check.reason
			var actual = gitignore.is_included(path_to_check)
			
			if actual == expected:
				print("  [PASS] '%s': expected included=%s, got=%s. (%s)" % [path_to_check, expected, actual, reason])
				passed_tests += 1
			else:
				print("  [FAIL] '%s': expected included=%s, got=%s. (%s)" % [path_to_check, expected, actual, reason])
				# Log detailed rule info for failed test for this specific path
				# print("    Rules applied to failed path '%s':" % path_to_check)
				# var temp_match_ignore_status = false
				# for rule_idx in range(gitignore._rules.size()):
				# 	 var r_debug = gitignore._rules[rule_idx]
				# 	 var matches_this_rule = r_debug.regex_object.search(path_to_check) != null
				# 	 if matches_this_rule:
				# 		 temp_match_ignore_status = not r_debug.is_negation
				# 	 print("      Rule %d: pattern='%s', regex='%s', negation=%s, MATCHED=%s, current_ignored_status=%s" % [
				# 		 rule_idx, r_debug.original_line_for_debug, r_debug.regex_object.get_pattern(), 
				# 		 r_debug.is_negation, matches_this_rule, temp_match_ignore_status
				# 	 ])


	print("\n--- Summary ---")
	print("Total tests: %d" % total_tests)
	print("Passed: %d" % passed_tests)
	print("Failed: %d" % (total_tests - passed_tests))

	if total_tests == passed_tests:
		print("All GitIgnore tests passed!")
	else:
		print("Some GitIgnore tests FAILED.") 
