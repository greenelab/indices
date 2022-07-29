# Download the citation data from the COCI version 14 citation dump
mkdir data/coci -p

wget https://figshare.com/ndownloader/articles/6741422/versions/14 -P data/coci
mv data/coci/14 data/coci/citations.zip

unzip data/coci/citations.zip -d data/coci
rm data/coci/citations.zip

for file in `ls data/coci/20*.zip`; do unzip $file -d data/; done
for file in `ls data/coci/20*.zip`; do rm $file -d data/; done

