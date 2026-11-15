"""Routing by hand: the layer ladder, from poly and diffusion up to met3.

Drawn upright, with the silicon at the bottom as in a cross-section, so the
figure is narrow enough to read on a phone.
"""
import schemdraw.elements as elm
import schemdraw.flow as flow

from circuit_style import drawing, save

BOX_W, BOX_H = 2.1, 0.65
RUNG = 1.15  # length of the wire between two layers, beside which the contact's name sits

d = drawing()
d.config(margin=0.5)  # a little white round the labels at the edges

# poly and diffusion side by side at the bottom, each with its own licon1,
# joining before li1
poly = d.add(flow.Box(w=BOX_W, h=BOX_H).label("poly").at((-1.5, 0)).anchor("S"))
diff = d.add(flow.Box(w=BOX_W, h=BOX_H).label("diffusion").at((1.5, 0)).anchor("S"))
join_y = poly.N[1] + RUNG
d.add(elm.Line().at(poly.N).toy(join_y).label("licon1", loc="top", ofst=0.15))
d.add(elm.Line().at(diff.N).toy(join_y).label("licon1", loc="bottom", ofst=0.15))
d.add(elm.Line().at((poly.N[0], join_y)).tox(diff.N[0]))
d.add(elm.Dot(radius=0.07).at((0, join_y)))

li1 = d.add(flow.Box(w=BOX_W, h=BOX_H).label("li1").at((0, join_y + 0.45)).anchor("S"))
d.add(elm.Line().at((0, join_y)).to(li1.S))

# then one rung at a time: a contact or via between each pair of layers
last = li1
for via, layer in (("mcon", "met1"), ("via1", "met2"), ("via2", "met3")):
    wire = d.add(elm.Line().at(last.N).up(RUNG).label(via, loc="bottom", ofst=0.15))
    last = d.add(flow.Box(w=BOX_W, h=BOX_H).label(layer).at(wire.end).anchor("S"))

d.add(elm.Line().at(last.N).up(0.55))
d.add(elm.Label().at((0, last.N[1] + 0.85)).label("..."))

print(save(d, "ad104-routing-layer-ladder"))
