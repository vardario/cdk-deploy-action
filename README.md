# Github CDK Deploy Action

This action allows you to deploy a given stack created through cdk synth.

## Template deployment

The stack template is deployed from the CDK assets bucket (`TemplateURL`) instead of being sent inline (`TemplateBody`), just like `cdk deploy`. This raises the template size limit from 51,200 bytes to 1 MB.

The template location is read from `stackTemplateAssetObjectUrl` in `<cdk-output-path>/manifest.json`. This requires:

- a modern CDK bootstrap (`cdk bootstrap` with the default/modern template), and
- the `DefaultStackSynthesizer` (the default in CDK v2).

The template is uploaded to the assets bucket as part of the regular asset publishing step, and no additional IAM permissions are needed. The CDK deploy role already has read access to the assets bucket.

If `stackTemplateAssetObjectUrl` is not present (e.g. when using a legacy synthesizer), the action prints a warning and falls back to deploying the local `<cdk-output-path>/<stack>.template.json` inline. It minifies the template first so it has a better chance of fitting under the 51,200 byte limit.
