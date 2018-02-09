# Install Drupal modules
wget https://raw.githubusercontent.com/fsulib/islandora7x_aws/master/FsuCustom/custom_drupal_modules.txt -O /tmp/custom_drupal_modules.txt
while read line
do
  echo $line
done < /tmp/custom_drupal_modules.txt

# Install Islandora modules
wget https://raw.githubusercontent.com/fsulib/islandora7x_aws/master/FsuCustom/custom_islandora_modules.txt -O /tmp/custom_islandora_modules.txt
while read line
do
  echo $line
done < /tmp/custom_islandora_modules.txt
