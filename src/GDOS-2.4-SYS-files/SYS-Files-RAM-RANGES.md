<!-- Provenance: stage b -- stock G-DOS 2.4, OMTI, 10 MB, drives 5
     and 6. 
     Scope: SYS files RAM ranges & start adresses
     Source: Grosser 
     Kapitel 7: SYS-Files und Aufbau des Directory Seite 7-1
     Betriebssysteme: NEWDOS/80 Version 2 für TRS-80 Model I+III
    GDOS für Genie I,II,IIs,III,Ills *)
    *) Die meisten hier gemachten Angaben gelten auch für die
    SYS-Files von GDOS, es werden jedoch nicht diejenigen
    SYS-Files beschrieben, die es nur in GDOS gibt.
    In den SYS-Files sind alle Befehle und Funktionen des DOS
    untergebracht. Die meisten benutzen den RAM-Bereich 4D00H
    bis 51FFH und wechseln sich dort so ab, wie sie gerade
    gebraucht werden. Für das Laden und Starten von SYS-Files
    ist UP GETSYS (4BC9H) zuständig, siehe Kapitel 3.
-------------------------------------------------------------
Chapter 7: SYS Files and the Structure of the Directory — Page 7‑1
Operating Systems:
NEWDOS/80 Version 2 for TRS‑80 Model I + III
GDOS for Genie I, II, IIs, III, IIIs\*)

\*) Most of the information given here also applies to the SYS files of GDOS; however, SYS files that exist only in GDOS are not described.

All commands and functions of the DOS are contained within the SYS files.
Most of them use the RAM area 4D00H to 51FFH, and they swap in and out of that region as needed.

The routine responsible for loading and starting SYS files is UP GETSYS (4BC9H) — see Chapter 3.
-->
# SYS Files – RAM Ranges & Start Addresses

- **SYS0/SYS** — EOF 1/5/0, RAM `400C–51DA`*, Start `4D00`
- **SYS1/SYS** — EOF 4/248, RAM `4D00–51DF`, Start `4D00`
- **SYS2/SYS** — EOF 4/197, RAM `4D00–51AC`, Start `4D00`
- **SYS3/SYS** — EOF 4/248, RAM `4D00–51DF`, Start `4D00`
- **SYS4/SYS** — EOF 5/0, RAM `4D00–51E7`, Start `4D00`
- **SYS5/SYS** — EOF 5/0, RAM `4D00–51E7`, Start `4D00`
- **SYS6/SYS** — EOF 34/235, RAM `4D00–6FF9`*, Start `4D00`
- **SYS7/SYS** — EOF 5/0, RAM `4D00–51E7`, Start `4D00`
- **SYS8/SYS** — EOF 5/0, RAM `4D00–51E7`, Start `4D00`
- **SYS9/SYS** — EOF 4/248, RAM `4D00–51DF`, Start `4D00`
- **SYS10/SYS** — EOF 5/0, RAM `4D00–51E7`, Start `4D00`
- **SYS11/SYS** — EOF 5/0, RAM `4D0C–51F3`, Start `4D0C`
- **SYS12/SYS** — EOF 4/235, RAM `4D00–51D2`, Start `4D00`

## Additional SYS Files

- **SYS13/SYS** — EOF 5/0, RAM `4D00–51E7`, Start `4D00`
- **SYS14/SYS** — EOF 5/0, RAM `4D00–51E7`, Start `4D00`
- **SYS15/SYS** — EOF 5/0, RAM `4D00–51E7`, Start `4D00`
- **SYS16/SYS** — EOF 5/0, RAM `4D00–51E7`, Start `4D00`
- **SYS17/SYS** — EOF 5/0, RAM `4D00–51E7`, Start `4D00`
- **SYS18/SYS** — EOF 5/0, RAM `5200–56E7`, Start `5200`
- **SYS19/SYS** — EOF 5/0, RAM `5200–56E7`, Start `5200`
- **SYS20/SYS** — EOF 5/0, RAM `5200–56E7`, Start `5200`
- **SYS21/SYS** — EOF 5/0, RAM `4D00–51E7`, Start `4D00`

## BASIC/CMD

- **BASIC/CMD** — EOF 17/154, RAM `5700–684D`*, Start `66BE`