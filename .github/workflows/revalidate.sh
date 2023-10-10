# modify this if you need to add data to the jwt payload
jwt_payload='{}'

if [ -z "$SECRET" ]; then
  echo "SECRET is not set" 1>&2
  exit 1
fi

# base64 encode, then replace '+' with '-', '/' with '_' and remove trailing '='
base64_encode () { openssl enc -base64 -A | tr '+/' '-_' | tr -d '='; }

# sign using HMAC with SHA256
HS256_sign () { openssl dgst -binary -sha256 -hmac "$SECRET"; }

# build jwt components
base64_header=$(echo -n '{"alg":"HS256","typ":"JWT"}' | base64_encode)
if [ -z "$base64_header" ]; then
  echo "Failed to build token header" 1>&2
  exit 1
fi

base64_payload=$(echo -n ${jwt_payload} | base64_encode)
if [ -z "$base64_payload" ]; then
  echo "Failed to build token payload" 1>&2
  exit 1
fi
base64_signature=$(echo -n "${base64_header}.${base64_payload}" | HS256_sign | base64_encode)
if [ -z "$base64_signature" ]; then
  echo "Failed to build token signature" 1>&2
  exit 1
fi

# assemble jwt token
token=${base64_header}.${base64_payload}.${base64_signature}

# trigger revalidation of personalhandbok
curl --fail-with-body https://apparatno.vercel.app/api/revalidateEmployeeHandbook \
  -H "Authorization: Bearer $token"

if [ $? -ne 0 ]; then
  echo "Failed to send revalidate request" 1>&2
  exit 1
fi
