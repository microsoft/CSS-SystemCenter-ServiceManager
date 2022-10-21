function Collect_ScomAgent() {
    AppendOutputToFileInTargetFolder (Reg query 'HKLM\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Agent Management Groups' -s 2>&1) AgentMGs.regValues.txt
}