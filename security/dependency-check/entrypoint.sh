#!/bin/bash

set -e

exit_env_error() {
    echo "Error: env var '${1}' not set" >&2
    exit 1
}

PROJECT_FOLDER="${PROJECT_FOLDER:-/project}"
OUTPUT_FOLDER="${OUTPUT_FOLDER:-/project}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-XML}"


[ -z "${SOURCE_REPO}" ] && exit_env_error SOURCE_REPO
[ -z "${DOJO_URL}" ] && exit_env_error DOJO_URL
[ -z "${DOJO_ENGAGEMENT_ID}" ] && exit_env_error DOJO_ENGAGEMENT_ID
[ -z "${DOJO_API_KEY}" ] && exit_env_error DOJO_API_KEY

rm -rf "${PROJECT_FOLDER}" "${OUTPUT_FOLDER}"
git clone "${SOURCE_REPO}" "${PROJECT_FOLDER}"

mkdir -p "${OUTPUT_FOLDER}"

chmod 777 /project/.nuget/NuGet.exe
mono /project/.nuget/NuGet.exe restore /project/Vattenfall.NL.Services.MijnNuon.sln -ConfigFile /project/NuGet.Config -NoCache | exit 0

/opt/dependency-check/bin/dependency-check.sh \
    --project "${PROJECT_FOLDER}" \
    --format "${OUTPUT_FORMAT}" \
    --out "${OUTPUT_FOLDER}" \
    --disableAssembly \
    --scan "${PROJECT_FOLDER}/"

cat "${OUTPUT_FOLDER}/dependency-check-report.xml"

curl -k --request POST --url "${DOJO_URL}"/api/v1/importscan/ --header 'authorization: ApiKey '"${DOJO_API_KEY}"' ' --header 'cache-control: no-cache' --header 'content-type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW' --form minimum_severity=Info --form scan_date=2018-05-01 --form verified=False --form file=@"${OUTPUT_FOLDER}"/dependency-check-report.xml --form tags=Test_automation --form active=True --form engagement=/api/v1/engagements/"${DOJO_ENGAGEMENT_ID}"/ --form 'scan_type=Dependency Check Scan'
