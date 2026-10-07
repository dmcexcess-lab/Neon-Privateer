extends SceneTree

const SOURCE_PATH := "res://assets/privateer_ui/privateer_ui_atlas.jpg"
const OUTPUT_PATH := "res://assets/privateer_ui/privateer_ui_atlas.res"

func _init() -> void:
    var bytes := FileAccess.get_file_as_bytes(SOURCE_PATH)
    if bytes.is_empty():
        push_error("Privateer art source JPEG is missing")
        quit(1)
        return

    var image := Image.new()
    var err := image.load_jpg_from_buffer(bytes)
    if err != OK:
        push_error("Privateer art JPEG decode failed: %s" % err)
        quit(1)
        return
    if image.get_width() != 390 or image.get_height() != 1228:
        push_error("Privateer art dimensions are %dx%d, expected 390x1228" % [image.get_width(), image.get_height()])
        quit(1)
        return

    var texture := ImageTexture.create_from_image(image)
    if texture == null:
        push_error("Privateer ImageTexture creation failed")
        quit(1)
        return

    err = ResourceSaver.save(texture, OUTPUT_PATH)
    if err != OK:
        push_error("Privateer native texture save failed: %s" % err)
        quit(1)
        return

    print("PRIVATEER ART RESOURCE OK 390x1228")
    quit()
