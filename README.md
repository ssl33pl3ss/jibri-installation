Jibri Docker
=============

Jibri provides services for recording or streaming a Jitsi Meet conference.

It works by launching a Chrome instance rendered in a virtual framebuffer and
capturing and encoding the output with ffmpeg. It is intended to be run on a
separate machine (or a VM), with no other applications using the display or
audio devices.

Only one recording at a time is supported on a single Jibri. Because of that,
Jibri instances in this installation would be dockerized.

## Installation

Jibri requires pre-configured [Jitsi Meet](https://github.com/jitsi/jitsi-meet)
server. It is recommended to have Jitsi Meet on its own dedicated server (or VM).

This installation uses **Ubuntu 20.04 Server** on both Jitsi Meet and Jibri servers.

### Jitsi configuration

At first your Jitsi Meet server has to be configured.

Add a VirtualHost for recorder:
```bash
sudo nano /etc/prosody/conf.avail/your.jitsidomain.com
```
```
VirtualHost "recorder.your.jitsidomain.com"
    modules_enabled = {
      "ping";
    }
    authentication = "internal_plain"
	c2s_require_encryption = false
    allow_empty_token = true
```
In the same file add muc_room_cache_size and c2s_require_encryption to internal.auth component:
```
Component "internal.auth.your.jitsidomain.com" "muc"
    storage = "none"
    modules_enabled = {
        "ping";
    }
    admins = { "focus@auth.your.jitsidomain.com", "jvb@auth.your.jitsidomain.com" }
    muc_room_locking = false
    muc_room_default_public_jids = true
    muc_room_cache_size = 1000
	c2s_require_encryption = false
```

Create two Prosody users. One for communication with Jibri and other for recording
meetings:
```bash
sudo prosodyctl register jibri auth.your.jitsidomain.com jibri_auth_password
sudo prosodyctl register recorder recorder.your.jitsidomain.com jibri_recorder_password
```
> **Note**
>
> If you are having a problem with `Prosody was unable to find lua-unbound` then install lua libraries based on lua version you have:
Check installed lua version by running `dpkg -l "lua*" | egrep "^ii"`
Then install required packages: `sudo apt install libunbound-dev liblua5.2-dev`
(install liblua\*.\*-dev package based on your version of lua)
After that install luaunbound package: `sudo luarocks install luaunbound`

Edit your Jicofo configuration file:
```bash
sudo nano /etc/jitsi/jicofo/sip-communicator.properties
```
```
org.jitsi.jicofo.auth.URL=XMPP:your.jitsidomain.com
org.jitsi.jicofo.jibri.BREWERY=JibriBrewery@internal.auth.your.jitsidomain.com
org.jitsi.jicofo.jibri.PENDING_TIMEOUT=90
```

Edit Jitsi config.js file to enable recordings:
```bash
sudo nano /etc/jitsi/meet/your.jitsidomain.com-config.js
```
Find a `hosts` section and add hiddenDomain:
```
...
hosts: {
        // XMPP domain.
        domain: 'your.jitsidomain.com',

        hiddenDomain: 'recorder.your.jitsidomain.com',
...
    },
...
```
In the same file find a `recordingService` section and enable it by uncommenting these lines:
```
...
 recordingService: {
    //     // When integrations like dropbox are enabled only that will be shown,
    //     // by enabling fileRecordingsServiceEnabled, we show both the integrations
    //     // and the generic recording service (its configuration and storage type
    //     // depends on jibri configuration)
        enabled: true,

    //     // Whether to show the possibility to share file recording with other people
    //     // (e.g. meeting participants), based on the actual implementation
    //     // on the backend.
    //     sharingEnabled: false,

    //     // Hide the warning that says we only store the recording for 24 hours.
    //     hideStorageWarning: false,
    },
...
```
You can also configure some recording settings here if you need.
> **Note** 
>
> If you want to enable a live streaming feature then find a `liveStreaming` section in this file and uncomment it the same way as `recordingService` section

Restart all of your Jitsi services:
```bash
sudo systemctl restart prosody.service jicofo.service jitsi-videobridge2.service
```

### Jibri configuration
Now configure your Jibri server. This installation uses 5 Jibri instances. You can add more, but remember to add 2 ALSA-loopback devices per Jibri instance.

Install the following package:
```bash
sudo apt update
sudo apt upgrade
sudo apt install linux-image-extra-virtual
```

Add ALSA-loopback devices to alsa-loopbakc config:
```bash
sudo nano /etc/modprobe.d/alsa-loopback.conf
```
```
options snd-aloop enable=1,1,1,1,1,1,1,1,1,1,1,1 index=0,1,2,3,4,5,6,7,8,9,10,11
```
Load it on boot:
```bash
sudo nano /etc/modules
```
```
snd-aloop
```
Load it into the existing Kernel:
```bash
modprobe snd-aloop
```
Check if it's working:
```bash
lsmod | grep snd_aloop
```
Output should be like this:
```
snd_aloop 24576 0
snd_pcm 98304 1 snd_aloop
snd 81920 3 snd_timer,snd_aloop,snd_pcm
```

Install Docker:
```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-compose
```
Check if Docker is installed successfully:
```bash
sudo docker run hello-world
```
Output should be like this:
```
Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
    1. The Docker client contacted the Docker daemon.
    2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
    3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
    4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
    $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
    https://hub.docker.com/

For more examples and ideas, visit:
    https://docs.docker.com/get-started/
```

Enable Docker sevice:
```bash
sudo systemctl enable docker
```

Clone Jibri Docker folder from this repository to /etc:
```bash
cd
git clone https://github.com/ssl33pl3ss/jibri-installation.git
sudo cp jibri-installation/jibridocker /etc
```

Create a folder for your Meetings recordings:
```bash
sudo mkdir /jitsi-recordings
```

Configure jibri.yml file in /etc/jibridocker directory:
```bash
sudo nano /etc/jibridocker/jibri.yml
```

Check the latest available release of Jitsi Docker image [here](https://github.com/jitsi/docker-jitsi-meet/releases) and edit image name in `image` section according to it.
In `environment` section change **your.jitsidomain.com** to your actual Jitsi domain, **IP_of_your_jitsi_server** to actual IP of your Jitsi server and **your/timezone** to your timezone.
You can also change `volumes` section if you are using different directories.
If you are planning on using more Jibri instances, add them into jibri.yml file and create .asoundrc_\* files with ALSA configuration in **asound** folder.
**finalize.sh** script could also be changed to your needs.

After configuration, check if everything is working:
```bash
cd /etc/jibridocker
sudo docker-compose -f jibri.yml up
```
At the end you sould see `INFO: [27] org.jitsi.xmpp.mucclient.MucClient.log() Joined MUC: jibribrewery@internal.auth.your.jitsidomain.com`
> **Note**
> 
> If your firewall is enabled and you get an error `org.jivesoftware.smack.SmackException$ConnectionException: The following addresses failed: 'your.jitsidomain.com:5222' failed because: your.jitsidomain.com/IP_of_your_jitsi_server exception: java.net.SocketTimeoutException: connect timed out` you should allow port 5222 by running `sudo ufw allow 5222`

If everything is working, stop the containers with `Ctrl + C` and run:
```bash
sudo docker-compose -f jibri.yml up -d
```

Check if containers are running:
```bash
sudo docker ps
```
The output should be:
```
| CONTAINER ID | IMAGE | COMMAND | CREATED | STATUS | PORTS | NAMES |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| id | jitsi/jibri:stable-8319 | "/init" | 1 minute ago | Up 1 minute |       | jibridocker_recorder_2_1 |
| id | jitsi/jibri:stable-8319 | "/init" | 1 minute ago | Up 1 minute |       | jibridocker_recorder_1_1 |
| id | jitsi/jibri:stable-8319 | "/init" | 1 minute ago | Up 1 minute |       | jibridocker_recorder_4_1 |
| id | jitsi/jibri:stable-8319 | "/init" | 1 minute ago | Up 1 minute |       | jibridocker_recorder_5_1 |
| id | jitsi/jibri:stable-8319 | "/init" | 1 minute ago | Up 1 minute |       | jibridocker_recorder_3_1 |
```
To check Docker container logs run:
```bash
sudo docker logs docker_container_name
```

To stop Docker containers run:
```bash
sudo docker-compose -f jibri.yml stop
```

To start Docker containers on boot run:
```bash
sudo docker update --restart always jibridocker_recorder_1_1 jibridocker_recorder_2_1 jibridocker_recorder_3_1 jibridocker_recorder_4_1 jibridocker_recorder_5_1
```

### Autostart
If you want to start recording automatically use [this](https://github.com/jitsi-contrib/prosody-plugins/tree/main/jibri_autostart) plugin.