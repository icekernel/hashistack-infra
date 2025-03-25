# docs

## Agent provisioner API

The agent provisioner API has been made availabe as a Lambda function that is
proxied by ApiGW.

It works by sending it a json mime type and a body payload with the desired
lifecycle and configuration:

eg. for destroying an instance

```
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "lifecycle": "destroy",
    "meta": {
      "customerId": "ABC123XYZ42"
    }
  }'
  https://enughwlwtc.execute-api.eu-central-1.amazonaws.com/prod1/provisioner
```

Example scripts that take the customerId as a parameter are available in the
[../bin](../bin/) directory.

## Accessing the launched agents

After agent instances finish building themselves and launching, the agent will
become available through the nginx proxy on a URL similar to this:

https://prod1-nginx.click1.prism/ABC123XYZ42/agents

Given that `ABC123XYZ42` would be the agent key you supplied in the
`eliza_config.meta.customerId` field of the json payload.

# ApiGW route
