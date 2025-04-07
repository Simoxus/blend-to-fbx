import bpy
import os
import sys

def export_to_fbx(mode="normal"):
    blend_file = bpy.data.filepath
    if not blend_file:
        print("No .blend file loaded.")
        return

    base_dir = os.path.dirname(blend_file)
    base_name = os.path.splitext(os.path.basename(blend_file))[0]
    fbx_path = os.path.join(base_dir, base_name + ".fbx")

    print(f"Exporting {blend_file} to {fbx_path} using mode: {mode}")

    if mode == "unity":
        bpy.ops.export_scene.unity_fbx(filepath=fbx_path)
    else:
        bpy.ops.export_scene.fbx(filepath=fbx_path)

# Get the export mode from command line args
mode = "normal"
if "--" in sys.argv:
    mode_index = sys.argv.index("--") + 1
    if mode_index < len(sys.argv):
        mode = sys.argv[mode_index]

export_to_fbx(mode)
