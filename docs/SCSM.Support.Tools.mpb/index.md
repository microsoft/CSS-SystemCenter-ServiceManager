[Do you want more tools in your SM Console?](https://github.com/microsoft/CSS-SystemCenter-ServiceManager/issues/new?assignees=khusmeno-MS&labels=4.+SCSM.Support.Tools.mpb%2C+enhancement&projects=&template=1--scsm-support-tools-mpb---feature-request.md&title=%5BNew+Idea+-+SCSM.Support.Tools.mpb%5D)
# SCSM Support Tools in the SCSM Console (MPB)

Download the latest MPB:  [SCSM.Support.Tools.mpb]({{ site.latestDownloadLink }}/SCSM.Support.Tools.mpb)

## Description
The *SCSM.Support.Tools.mpb* has been developed to bring useful tools into the SM Console. When this Management Pack Bundle (MPB) is imported, tools will appear under the "Administration" tree on the left.

> <img width="550" alt="SCSM Support Tools when imported into the SM Console" src="https://github.com/microsoft/CSS-SystemCenter-ServiceManager/assets/99029864/ec2bfe03-47f7-4009-b37e-e9d2b4190106">

As an example, you can view the Health Status of your Management Servers. (After importing this MPB, the _SCSM Diagnostic Tool_ will run *automatically* on your Management Servers at 02:30 AM to determine their Health Status.)
> <img width="584" alt="Health Status of your Management Servers" src="https://github.com/microsoft/CSS-SystemCenter-ServiceManager/assets/99029864/6d15d1af-2675-41b5-9f59-fbbc2b5d9287">

You can also configure to send emails whenever the SCSM Diagnostic Tool runs on your Management Servers.
> <img width="511" alt="configure to send emails" src="https://github.com/microsoft/CSS-SystemCenter-ServiceManager/assets/99029864/766c56e0-ace2-4a82-9ab7-48831ee922a7">

The configured Recipients will get an email similar to this:
> <img width="813" alt="A sample email sent to configured Recipients" src="https://github.com/microsoft/CSS-SystemCenter-ServiceManager/assets/99029864/7fd47300-ab2f-4e8f-96d8-8e15abb3e34b">

## How to get new tools?
A "rule" contained in the MPB will update itself at 02:00 AM if the Management Servers can reach GitHub. If not, the latest MPB can be downloaded and imported manually.

## How to uninstall this MPB?
We strongly believe that this MPB contains useful tools, however in case you want to uninstall, just delete the Management Packs starting with "SCSM Support Tools".
> <img width="480" alt="image" src="https://github.com/microsoft/CSS-SystemCenter-ServiceManager/assets/99029864/b0be1764-1d2c-4c58-8d3e-e8f2a79f6099">

## Minimum requirements
- Service Manager 2019 or later

## Do you want to contribute to this tool?

[Here]({{ site.GitHubRepoLink }}/SCSM.Support.Tools.mpb/) is the GitHub repo.
