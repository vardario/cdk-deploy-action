#!/usr/bin/env bash
# Resolves the CloudFormation template location for a synthesized CDK stack.
# Prints an S3 HTTPS URL if the manifest has stackTemplateAssetObjectUrl,
# otherwise a minified local template path.
#
# Required env: CDK_OUTPUT_PATH, STACK_NAME, ACCOUNT_ID, REGION
set -euo pipefail

: "${CDK_OUTPUT_PATH:?CDK_OUTPUT_PATH is required}"
: "${STACK_NAME:?STACK_NAME is required}"
: "${ACCOUNT_ID:?ACCOUNT_ID is required}"
: "${REGION:?REGION is required}"

manifest="${CDK_OUTPUT_PATH}/manifest.json"

url=""
if [[ -f "$manifest" ]]; then
  url="$(jq -r --arg stack "$STACK_NAME" '.artifacts[$stack].properties.stackTemplateAssetObjectUrl // empty' "$manifest")"
fi

if [[ -n "$url" ]]; then
  url="${url//\$\{AWS::AccountId\}/$ACCOUNT_ID}"
  url="${url//\$\{AWS::Region\}/$REGION}"
  url="${url//\$\{AWS::Partition\}/aws}"

  if [[ "$url" != s3://* ]]; then
    echo "::error::Unexpected stackTemplateAssetObjectUrl format: $url" >&2
    exit 1
  fi

  path="${url#s3://}"
  bucket="${path%%/*}"
  key="${path#*/}"
  if [[ -z "$bucket" || -z "$key" || "$key" == "$path" ]]; then
    echo "::error::Could not parse bucket/key from stackTemplateAssetObjectUrl: $url" >&2
    exit 1
  fi

  echo "https://${bucket}.s3.${REGION}.amazonaws.com/${key}"
  exit 0
fi

template="${CDK_OUTPUT_PATH}/${STACK_NAME}.template.json"
echo "::warning::stackTemplateAssetObjectUrl not found for stack '${STACK_NAME}' in ${manifest}; falling back to inline template ${template} (limited to 51,200 bytes)." >&2

tmp="$(mktemp)"
jq -c . "$template" > "$tmp"
mv "$tmp" "$template"

echo "$template"
