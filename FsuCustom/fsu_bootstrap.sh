# Install Drupal modules
wget https://raw.githubusercontent.com/fsulib/islandora7x_aws/master/FsuCustom/custom_drupal_modules.txt -O /tmp/custom_drupal_modules.txt
while read line
do
  /root/.composer/vendor/bin/drush --root=/var/www/html -y dl $line
  /root/.composer/vendor/bin/drush --root=/var/www/html -y en $line
done < /tmp/custom_drupal_modules.txt

# Install Islandora modules
wget https://raw.githubusercontent.com/fsulib/islandora7x_aws/master/FsuCustom/custom_islandora_modules.txt -O /tmp/custom_islandora_modules.txt
while read line
do
  git clone https://github.com/$line
  #/root/.composer/vendor/bin/drush --root=/var/www/html -y en $line
done < /tmp/custom_islandora_modules.txt
