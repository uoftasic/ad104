"""SKY130 layer map: the contact ladder, with the GDS layer numbers.

Drawn upright, with the silicon at the bottom as in a cross-section, so the
figure is narrow enough to read on a phone.
"""
import schemdraw.elements as elm
import schemdraw.flow as flow

from circuit_style import drawing, save

BOX_W, BOX_H = 2.9, 0.65
RUNG = 1.15  # length of the wire between two layers, beside which the contact's name sits

d = drawing()
d.config(margin=0.5)  # a little white round the labels at the edges

# poly and diff join first, and share the one licon1 rung up to li1
poly = d.add(flow.Box(w=1.5, h=BOX_H).label("poly").at((-1.2, 0)).anchor("S"))
diff = d.add(flow.Box(w=1.5, h=BOX_H).label("diff").at((1.2, 0)).anchor("S"))
join_y = poly.N[1] + 0.6
d.add(elm.Line().at(poly.N).toy(join_y))
d.add(elm.Line().at(diff.N).toy(join_y))
d.add(elm.Line().at((poly.N[0], join_y)).tox(diff.N[0]))
d.add(elm.Dot(radius=0.07).at((0, join_y)))

last = None
start = (0, join_y)
for via, layer in (("licon1 (66/44)", "li1 (67/20)"),
                   ("mcon (67/44)", "met1 (68/20)"),
                   ("via1", "met2")):
    wire = d.add(elm.Line().at(start).up(RUNG).label(via, loc="bottom", ofst=0.15))
    last = d.add(flow.Box(w=BOX_W, h=BOX_H).label(layer).at(wire.end).anchor("S"))
    start = last.N

d.add(elm.Line().at(last.N).up(0.55))
d.add(elm.Label().at((0, last.N[1] + 0.85)).label("..."))

print(save(d, "ad104-layer-map-contact-ladder"))
