# OpSec-Package
# RIP An0nSec666
The original code that was used for this OP Sec script was written by the late great An0nSec666 RIP!

Talking to him shortly before his death he agreed that his code should be fixed up to run on newer linux systems, so that people who live in places where censorship is ripe would be able to share their voice while remaining anonymous, unfortunetly he passed before being able to do so, therefore, I took it upon myself to do just that and release it to the public.

This code only runs on Debian based systems such as Debian, Ubuntu, Mint etc but can likely be adapted to run on other linux distros, feel free to do so!


# Download:
git clone https://github.com/UbuntuStrike/OpSec-Package.git

cd OpSec-Package

chmod +x install.sh

# Install (Run as root)
## IMPORTANT!!!

If running in a VM run:
./install.sh vm 

If running on bare metal run:
./install.sh normal

# Usage (Must be run as root)

This can be run two different ways..

To run as a basic transparent proxy for Tor run:

Start

./opsectunnel.sh start 

Stop

./opsectunnel.sh stop

If you would like to run the more advanced mode that also includes i2p, JonDo and Tor run:
(jondo can be set as a proxy in your browser on port 4001 while i2p can be used for http on port 4444, https on 4445 and irc on 6668 or 6669)

Start 

./proxy.sh start
(ctrl + c to kill)

Stop

./proxy.sh st

