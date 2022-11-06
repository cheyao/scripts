import gdstk 
import pathlib 

gds = sorted(pathlib.Path('runs').glob('wokwi/results/final/gds/*.gds')) 
library = gdstk.read_gds(gds[-1]) 
top_cells = library.top_level() 
top_cells[0].write_svg('gds_render.svg') 