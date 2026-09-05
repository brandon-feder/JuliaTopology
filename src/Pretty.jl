"""
Terminal formatting helpers: colored `[INF]`/`[IMP]`/`[SUC]` tags and a
timestamp string, for status output in scripts and examples.
"""
module Pretty
    TIME = () -> rpad(string(Time(now())), 12)
    TAB = "     "
    IMP = "[\e[1;35mIMP\e[0m]"
    INF = "[\e[1;36mINF\e[0m]"
    SUC = "[\e[1;32mSUC\e[0m]"

    export TIME, TAB, INF, IMP, SUC
end