class_name WebImage

static func load_image_from_url(url: String, target:TextureRect):
	Logger.info("Loading image from URL: " + str(url))
	var http_request = HTTPRequest.new()
	target.add_child(http_request)
	http_request.request_completed.connect(on_request_completed.bind(target))
	var err = http_request.request(url)
	if err != OK:
		Logger.error("Failed to load image from URL: " + url)
		return
	else:
		# Logger.info("Requested image...")
		pass
	
static func on_request_completed(result: int, _response_code: int, headers: PackedStringArray, body:PackedByteArray, target:TextureRect):
	if result == HTTPRequest.RESULT_SUCCESS:
		var mime_type = get_mime_type(headers)
		
		match mime_type:
			"image/png":
				load_as_png(body, target)
			"image/jpeg":
				load_as_jpg(body, target)
			"image/jpg":
				load_as_jpg(body, target)
			"image/gif":
				load_as_gif(body, target)
			_:
				Logger.error("Unknown mime type: " + str(mime_type))
	else:
		Logger.error("Failed to load image from URL: " + str(result))

static func get_mime_type(headers: PackedStringArray) -> String:
	for header in headers:
		if header.begins_with("Content-Type: "):
			return header.split(": ")[1].strip_edges()
	
	return "unknown"
	
static func load_as_png(buffer:PackedByteArray, target:TextureRect):
	Logger.info("Loading texture as PNG...")
	var image = Image.new()
	var err = image.load_png_from_buffer(buffer)
	if err != OK:
		Logger.error("Failed to parse PNG image from data: " + str(err))
		return
	
	target.texture = ImageTexture.create_from_image(image)

static func load_as_jpg(buffer:PackedByteArray, target:TextureRect):
	Logger.info("Loading texture as JPG...")
	var image = Image.new()
	var err = image.load_jpg_from_buffer(buffer)
	if err != OK:
		Logger.error("Failed to parse JPEG image from data: " + str(err))
		return
	
	target.texture = ImageTexture.create_from_image(image)
	
static func load_as_gif(buffer:PackedByteArray, target:TextureRect):
	print("Loading texture as GIF...")
	var texture:AnimatedTexture = GifManager.animated_texture_from_buffer(buffer)
	target.texture = texture
	
static func load_from_path(path:String, target:TextureRect):
	print("Loading texture from path...")
	if path.ends_with(".gif"):
		var texture:AnimatedTexture = GifManager.animated_texture_from_file(path)
		target.texture = texture
	else:
		var image = Image.new()
		var err = image.load(path)
		if err != OK:
			Logger.error("Failed to parse image from path: " + path)
			return
		target.texture = ImageTexture.create_from_image(image)

static func get_byte_size_from_path(path:String) -> int:
	var bytes = FileAccess.get_file_as_bytes(path)
	return bytes.size()
