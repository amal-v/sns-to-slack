var https = require('https');
var util = require('util');

exports.handler = function (event, context) {
    console.log('From SNS:', event.Records[0].Sns);
    console.log('From SNS:', event.Records[0].Sns.Message);
    var message = JSON.parse(event.Records[0].Sns.Message);
    var priority = "good";
    var AlarmReason = "Alarm Is back to Normal";
    var fields = [];
    if (message.NewStateValue == 'ALARM') {
        priority = "danger";
        AlarmReason = message.NewStateReason;
    }
    var postData = {
        "channel": process.env.channel_name,
        "username": "AWS Cloudwatch Bot",
        "text": "*" + event.Records[0].Sns.Subject + "*",
        "icon_emoji": ":bell:"
    };
    fields = [
        {
            "value": "*Name:* " + message.AlarmName
        },
        {
            "value": "*Description:* " + message.AlarmDescription
        },
        {
            "value": "*Reason:* " + AlarmReason
        },
        {
            "value": "*Time:* " + message.StateChangeTime
        }];
    postData.attachments = [
        {
            "color": priority,
            "fields": fields,
            "mrkdwn_in": ["text", "fields"]
        }];

    var options = {
        method: 'POST',
        hostname: 'hooks.slack.com',
        port: 443,
        path: process.env.slack_web_hook
    };

    var req = https.request(options, function (res) {
        res.setEncoding('utf8');
        res.on('data', function (chunk) {
            context.done(null);
        });
    });
    req.on('error', function (e) {
        console.log('problem with request: ' + e.message);
    });
    req.write(util.format("%j", postData));
    req.end();
};