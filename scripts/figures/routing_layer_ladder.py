"""Routing by hand: the layer ladder, from poly and diffusion up to met3."""
import schemdraw.elements as elm
import schemdraw.flow as flow

from circuit_style import drawing, save

BOX_H = 0.8
GAP = 2.2  # length of the wire between two layers, room for the contact's name

d = drawing()

# poly and diffusion, each with its own licon1, joining before li1
poly = d.add(flow.Box(w=2.4, h=BOX_H).label("poly").at((0, 0.9)).anchor("W"))
diff = d.add(flow.Box(w=2.4, h=BOX_H).label("diffusion").at((0, -0.9)).anchor("W"))
join_x = poly.E[0] + GAP
d.add(elm.Line().at(poly.E).tox(join_x).label("licon1", loc="top"))
d.add(elm.Line().at(diff.E).tox(join_x).label("licon1", loc="bottom"))
d.add(elm.Line().at((join_x, poly.E[1])).toy(diff.E[1]))
d.add(elm.Dot(radius=0.07).at((join_x, 0)))

li1 = d.add(flow.Box(w=1.5, h=BOX_H).label("li1").at((join_x + 0.9, 0)).anchor("W"))
d.add(elm.Line().at((join_x, 0)).to(li1.W))

# then one rung at a time: a contact or via between each pair of layers
last = li1
for via, layer in (("mcon", "met1"), ("via1", "met2"), ("via2", "met3")):
    wire = d.add(elm.Line().at(last.E).right(GAP).label(via, loc="top"))
    last = d.add(flow.Box(w=1.5, h=BOX_H).label(layer).at(wire.end).anchor("W"))

d.add(elm.Line().at(last.E).right(0.9))
d.add(elm.Label().at((last.E[0] + 1.35, 0)).label("..."))

print(save(d, "ad104-routing-layer-ladder"))
