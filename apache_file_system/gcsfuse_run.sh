#!/usr/bin/env bash
# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# [START cloudrun_fuse_script]
#!/usr/bin/env bash
set -eo pipefail
echo "Service account activated."
mkdir -p /var/www/html/config
gcsfuse --key-file=/service_acc.json --debug_gcs --debug_fuse -o allow_other -o nonempty --dir-mode=777 --file-mode=777 matomo-config /var/www/html/config
# Copy all files from /temp_plugins to /var/www/html/plugins
chmod a+w /var/www/html/config
# Put the chmod permissions of /var/www/html/lang/.htaccess to 0644"
#chmod 0644 /var/www/html/lang/.htaccess
#chmod 0644 /var/www/html/config/.htaccess
#chmod 0644 /var/www/html/tmp/.htaccess

echo "Files mounted."
chmod +x /entrypoint.sh
echo "entrypoint.sh is executable."
# Execute docker-entrypoint.sh
/entrypoint.sh

apache2-foreground
# Exit immediately when one of the background processes terminate.
wait -n
# [END cloudrun_fuse_script]