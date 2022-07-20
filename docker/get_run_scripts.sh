branch="separate_run_scripts"
set -ex
dir_url="https://api.github.com/repos/IMIO/imio.updates/contents/src/imio/updates/scripts?ref=$branch"
urls=$(curl -sf --header 'application/vnd.github.v3.raw' --location "$dir_url" | grep \"download_url\" | cut -d '"' -f4)

mkdir -p scripts
cd scripts
for url in $urls
do
  curl -sfO "$url"
done