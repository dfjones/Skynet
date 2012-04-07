# Requirements

npm install coffee-script

npm install node-xmpp

npm install request

# Setup

You should create a file called 'account.coffee' with the following

```coffee-script
config =
  jabberId: "xxx_xxx@chat.hipchat.com"
  password: "password"
  roomJids: ["xxx_xxx@conf.hipchat.com", "yyy_yy@conf.hipchat.com"]
  roomNick: "Nick"

module.exports = config
```

# Run
coffee skynet.coffee
