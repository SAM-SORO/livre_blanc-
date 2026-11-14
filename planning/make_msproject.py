# -*- coding: utf-8 -*-
"""Génère le planning au format XML de Microsoft Project (MSPDI), ouvrable par Fichier > Ouvrir dans MS Project."""
import datetime as dt
import os, sys
from xml.sax.saxutils import escape as e

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import plan as P

rows = P.resolved()
uid = {r["wbs"]: i + 1 for i, r in enumerate(rows)}
leaves = [r for r in rows if not r["summary"] and not r["milestone"]]


def ts(d, end=False):
    return d.isoformat() + ("T17:00:00" if end else "T08:00:00")


def hours(n):
    return "PT%dH0M0S" % (n * 8)


# unités d'affectation : la rédaction continue pèse 10 % ; les autres tâches se partagent le reste
def units(r):
    if r["wbs"] == "6.1":
        return 0.1
    d, conc = r["start"], 1
    while d <= r["finish"]:
        c = sum(1 for k in leaves if k["wbs"] != "6.1" and k["start"] <= d <= k["finish"])
        conc = max(conc, c)
        d += dt.timedelta(days=1)
    return round(0.9 / conc, 2)


out = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
       '<Project xmlns="http://schemas.microsoft.com/project">',
       "<SaveVersion>14</SaveVersion>", "<Name>%s</Name>" % e(P.PROJECT_NAME),
       "<Title>%s</Title>" % e(P.PROJECT_NAME), "<Author>SORO Koromiwonah Segneniguetenin Samuel</Author>",
       "<ScheduleFromStart>1</ScheduleFromStart>",
       "<StartDate>%s</StartDate>" % ts(P.START), "<FinishDate>%s</FinishDate>" % ts(P.FINISH, True),
       "<CalendarUID>1</CalendarUID>", "<DefaultStartTime>08:00:00</DefaultStartTime>",
       "<DefaultFinishTime>17:00:00</DefaultFinishTime>", "<MinutesPerDay>480</MinutesPerDay>",
       "<MinutesPerWeek>2400</MinutesPerWeek>", "<DaysPerMonth>20</DaysPerMonth>",
       "<DurationFormat>7</DurationFormat>", "<WeekStartDay>1</WeekStartDay>",
       "<Calendars><Calendar><UID>1</UID><Name>Standard</Name><IsBaseCalendar>1</IsBaseCalendar><WeekDays>"]
for day in range(1, 8):
    if day in (1, 7):
        out.append("<WeekDay><DayType>%d</DayType><DayWorking>0</DayWorking></WeekDay>" % day)
    else:
        out.append("<WeekDay><DayType>%d</DayType><DayWorking>1</DayWorking><WorkingTimes>"
                   "<WorkingTime><FromTime>08:00:00</FromTime><ToTime>12:00:00</ToTime></WorkingTime>"
                   "<WorkingTime><FromTime>13:00:00</FromTime><ToTime>17:00:00</ToTime></WorkingTime>"
                   "</WorkingTimes></WeekDay>" % day)
for d, name in sorted(P.HOLIDAYS.items()):
    out.append("<WeekDay><DayType>0</DayType><DayWorking>0</DayWorking><TimePeriod><FromDate>%sT00:00:00</FromDate>"
               "<ToDate>%sT23:59:00</ToDate></TimePeriod></WeekDay>" % (d.isoformat(), d.isoformat()))
out.append("</WeekDays></Calendar></Calendars><Tasks>")
out.append("<Task><UID>0</UID><ID>0</ID><Name>%s</Name><Type>1</Type><IsNull>0</IsNull><OutlineNumber>0</OutlineNumber>"
           "<OutlineLevel>0</OutlineLevel><Start>%s</Start><Finish>%s</Finish><Summary>1</Summary></Task>"
           % (e(P.PROJECT_NAME), ts(P.START), ts(P.FINISH, True)))
for i, r in enumerate(rows):
    start = ts(r["finish"], True) if r["milestone"] else ts(r["start"])
    x = ["<Task>", "<UID>%d</UID><ID>%d</ID>" % (uid[r["wbs"]], i + 1), "<Name>%s</Name>" % e(r["name"]),
         "<Type>1</Type><IsNull>0</IsNull>", "<WBS>%s</WBS><OutlineNumber>%s</OutlineNumber>" % (r["wbs"], r["wbs"]),
         "<OutlineLevel>%d</OutlineLevel>" % r["level"], "<Start>%s</Start><Finish>%s</Finish>" % (start, ts(r["finish"], True)),
         "<Duration>%s</Duration><DurationFormat>7</DurationFormat>" % hours(r["days"]),
         "<Milestone>%d</Milestone><Summary>%d</Summary>" % (r["milestone"], r["summary"])]
    if not r["summary"]:
        x.append("<ConstraintType>4</ConstraintType><ConstraintDate>%s</ConstraintDate>" % start)
        for p in r["pred"]:
            x.append("<PredecessorLink><PredecessorUID>%d</PredecessorUID><Type>1</Type><CrossProject>0</CrossProject>"
                     "<LinkLag>0</LinkLag><LagFormat>7</LagFormat></PredecessorLink>" % uid[p])
    x.append("</Task>")
    out.append("".join(x))
out.append("</Tasks><Resources>")
out.append("<Resource><UID>0</UID><ID>0</ID><IsNull>0</IsNull><Type>1</Type></Resource>")
for i, (name, ini, lead) in enumerate(P.TEAM):
    label = name + (" (responsable d'équipe)" if lead else "")
    out.append("<Resource><UID>%d</UID><ID>%d</ID><Name>%s</Name><Type>1</Type><IsNull>0</IsNull><Initials>%s</Initials>"
               "<Group>Équipe projet</Group><MaxUnits>1.00</MaxUnits><CalendarUID>1</CalendarUID></Resource>"
               % (i + 1, i + 1, e(label), ini))
out.append("</Resources><Assignments>")
a = 0
for r in leaves:
    u = units(r)
    for j in range(len(P.TEAM)):
        a += 1
        out.append("<Assignment><UID>%d</UID><TaskUID>%d</TaskUID><ResourceUID>%d</ResourceUID><Finish>%s</Finish>"
                   "<Start>%s</Start><Units>%.2f</Units>"
                   "<Work>PT%dH0M0S</Work></Assignment>"
                   % (a, uid[r["wbs"]], j + 1, ts(r["finish"], True), ts(r["start"]), u, round(r["days"] * 8 * u)))
out.append("</Assignments></Project>")
path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "Planning_Livre_Blanc_Citoyen.xml")
open(path, "w", encoding="utf8").write("\n".join(out))
print(path, len(rows), "tâches,", a, "affectations")
