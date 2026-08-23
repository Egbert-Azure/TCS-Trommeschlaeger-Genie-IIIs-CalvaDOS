# Artefacts

Four write-ups that answer one question each, kept as standalone pages rather
than folded into the reference or architecture docs, with the diagrams and
tables that go with them.

| Page | Answers |
| --- | --- |
| [The machine boots from the hard disk](boot-trace.md) | What happens between power-on and the prompt, and the nine criteria that check it |
| [What CalvaDOS actually changes](patch-inventory.md) | Every byte this port changes in stock GDOS 2.4, and the driver it adds |
| [Drive Dispatch Map](drive-dispatch-map.md) | How `DRVSEL` routes each DOS drive number to a floppy, an OMTI volume, or a rejection |
| [Two Sectors, One Burst](two-sectors-one-burst.md) | How the driver packs two 256-byte GDOS sectors into one 512-byte OMTI transfer |

They restate what the rest of `docs/` and the source already establish, so
where the two disagree the source wins. Each page names what it was drawn
from at the bottom.
