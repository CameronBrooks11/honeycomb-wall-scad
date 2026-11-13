default:
    @just --list

# Render the wall, inserts, clips and attachments, and check their geometry
test:
    python3 tests/test_hsw.py

# Render the README pictures into assets/
images:
    @mkdir -p assets
    montage -version >/dev/null
    openscad --render --colorscheme=Tomorrow --imgsize=700,500 --viewall --autocenter --camera=0,0,0,45,0,20,600 -D column_data_index=1 -o assets/wall.png honeycomb-wall.scad
    openscad --render --colorscheme=Tomorrow --imgsize=500,400 --viewall --autocenter --camera=0,0,0,40,0,200,250 -D 'layout=[[1,2,3],[4,5],[6,7,8]]' -o assets/inserts.png examples/inserts.scad
    openscad --render --colorscheme=Tomorrow --imgsize=300,300 --viewall --autocenter --camera=0,0,0,60,0,30,90 -D generate_clip=true -D generate_clip_hex_base=true -o assets/a-clip.png hsw-clips/hsw_clip.scad
    openscad --render --colorscheme=Tomorrow --imgsize=300,300 --viewall --autocenter --camera=0,0,0,70,0,40,500 -o assets/a-hook.png attachments/hook.scad
    openscad --render --colorscheme=Tomorrow --imgsize=300,300 --viewall --autocenter --camera=0,0,0,60,0,30,200 -o assets/a-plier.png attachments/plier_holder.scad
    openscad --render --colorscheme=Tomorrow --imgsize=300,300 --viewall --autocenter --camera=0,0,0,60,0,20,400 -o assets/a-rack.png attachments/tool_holder.scad
    montage -label 'clip, hex base' assets/a-clip.png -label 'hook' assets/a-hook.png -label 'plier holder' assets/a-plier.png -label 'tool rack' assets/a-rack.png -tile 4x1 -geometry +4+4 assets/parts.png
    rm assets/a-clip.png assets/a-hook.png assets/a-plier.png assets/a-rack.png
