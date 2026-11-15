"""SKY130 layer map: the contact ladder, with the GDS layer numbers."""
import schemdraw.elements as elm
import schemdraw.flow as flow

from circuit_style import drawing, save

BOX_H = 1.25
GAP = 3.5  # length of the wire between two layers, room for the contact's name

d = drawing()

# poly and diff join first, and share the one licon1 rung up to li1
poly = d.add(flow.Box(w=1.5, h=0.8).label("poly").at((0, 0.9)).anchor("W"))
diff = d.add(flow.Box(w=1.5, h=0.8).label("diff").at((0, -0.9)).anchor("W"))
join_x = poly.E[0] + 0.9
d.add(elm.Line().at(poly.E).tox(join_x))
d.add(elm.Line().at(diff.E).tox(join_x))
d.add(elm.Line().at((join_x, poly.E[1])).toy(diff.E[1]))
d.add(elm.Dot(radius=0.07).at((join_x, 0)))

last = None
start = (join_x, 0)
for via, layer in (("licon1 (66/44)", "li1\n(67/20)"),
                   ("mcon (67/44)", "met1\n(68/20)"),
                   ("via1", "met2")):
    wire = d.add(elm.Line().at(start).right(GAP).label(via, loc="top"))
    last = d.add(flow.Box(w=1.8, h=BOX_H).label(layer).at(wire.end).anchor("W"))
    start = last.E

d.add(elm.Line().at(last.E).right(0.9))
d.add(elm.Label().at((last.E[0] + 1.35, 0)).label("..."))

print(save(d, "ad104-layer-map-contact-ladder"))
