#!/bin/bash
#set the number of slaves
cd $HADOOP_PREFIX/etc/hadoop
echo "Type the number of slave nodes, followed by [ENTER]:"
read nslaves
for i in `seq 1 $nslaves`;
do
	echo "slave$i.cloudsuite.com" >> slaves
done;

echo "Please select classification or clustering (1 for classification and 2 for clustering:" 
echo "1. classification"
echo "2. clustering "

read mtype


#Preparing Hadoop
hdfs namenode -format
service ssh start
$HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

#Set the memory for mahout
export HADOOP_CLIENT_OPTS="-Xmx20192m"
export HADOOP_HOME=/opt/new_analytic/apache-mahout-distribution-0.11.0
rm /tmp/*.pid

# installing libraries if any - (resource urls added comma separated to the ACP system variable)
cd $HADOOP_PREFIX/share/hadoop/common ; for cp in ${ACP//,/ }; do  echo == $cp; curl -LO $cp ; done; cd -

# Start Hadoop
$HADOOP_PREFIX/sbin/start-dfs.sh
$HADOOP_PREFIX/sbin/start-yarn.sh

# classification
if [ $mtype -eq 1 ]; then

# Create a workdir for mahout
export WORK_DIR=${MAHOUT_HOME}/examples/temp/mahout-work-wiki
mkdir -p ${WORK_DIR}
cd $WORK_DIR
mkdir wikixml
cd wikixml

if [ -e enwiki-latest-pages-articles.xml ] 
then
  echo "The dataset is available."
elif [ -e enwiki-latest-pages-articles.xml.bz2 ]
then
  echo "unzip the data file ..." 
  bzip2 -d enwiki-latest-pages-articles.xml.bz2
else
  echo "Please select a number to choose the dataset size: 1. Partial small (149MB zipped), 2. Partial larger (317MB zipped), 3. Full wikipedia (10GB zipped)"
  read -p "Enter your choice : " choice
  if [ "$choice" == "1" ]
  then
  echo "Getting the partial small dataset... It takes time..."
  curl https://dumps.wikimedia.org/enwiki/latest/enwiki-latest-pages-articles1.xml-p000000010p000030302.bz2 -o ${WORK_DIR}/wikixml/enwiki-latest-pages-articles.xml.bz2
  elif [ "$choice" == "2" ]
  then
  echo "Getting the partial larger dataset... It takes time..."
  curl https://dumps.wikimedia.org/enwiki/latest/enwiki-latest-pages-articles10.xml-p002336425p003046511.bz2 -o ${WORK_DIR}/wikixml/enwiki-latest-pages-articles.xml.bz2
  else
  echo "Getting the full dataset... It takes time..."
  curl https://dumps.wikimedia.org/enwiki/latest/enwiki-latest-pages-articles.xml.bz2 -o ${WORK_DIR}/wikixml/enwiki-latest-pages-articles.xml.bz2
  fi
  echo "unzip the data file ..." 
  bzip2 -d enwiki-latest-pages-articles.xml.bz2
fi

# Put the dataset to HDFS 
hdfs dfs -rm ${WORK_DIR}/wikixml
hdfs dfs -mkdir -p ${WORK_DIR}
hdfs dfs -put ${WORK_DIR}/wikixml ${WORK_DIR}/wikixml

#run the algorithm
echo "Creating sequence files from wikiXML"
mahout seqwiki -c ${MAHOUT_HOME}/examples/temp/categories.txt -i ${WORK_DIR}/wikixml/enwiki-latest-pages-articles.xml -o ${WORK_DIR}/wikipediainput

echo "Converting sequence files to vectors using bigrams"
mahout seq2sparse -i ${WORK_DIR}/wikipediainput -o ${WORK_DIR}/wikipediaVecs -lnorm -nv -wt tfidf -ow -ng 2

echo "Creating training and holdout set with a random 80-20 split of the generated vector dataset"
mahout split -i ${WORK_DIR}/wikipediaVecs/tfidf-vectors --trainingOutput ${WORK_DIR}/training --testOutput  ${WORK_DIR}/testing -rp 20 -ow -seq -xm sequential 

echo "Training Bayes model"
mahout trainnb -i ${WORK_DIR}/training -o ${WORK_DIR}/model -li ${WORK_DIR}/labelindex -ow -c

echo "Testing on holdout set: Bayes"
mahout testnb -i  ${WORK_DIR}/testing -m ${WORK_DIR}/model -l ${WORK_DIR}/labelindex -ow -o ${WORK_DIR}/output -seq


#clustring
else 

SCRIPT_PATH=${0%/*}
if [ "$0" != "$SCRIPT_PATH" ] && [ "$SCRIPT_PATH" != "" ]; then 
  cd $SCRIPT_PATH
fi
START_PATH=`pwd`

# Set commands for dfs
source $HADOOP_HOME/examples/bin/set-dfs-commands.sh

if [[ -z "$MAHOUT_WORK_DIR" ]]; then
  WORK_DIR=/tmp/mahout-work-$nslaves
else
  WORK_DIR=$MAHOUT_WORK_DIR
fi
  $DFS -mkdir -p $WORK_DIR
  mkdir -p $WORK_DIR
  echo "Creating work directory at ${WORK_DIR}"

if [ ! -e ${WORK_DIR}/reuters-out-seqdir ]; then
  if [ ! -e ${WORK_DIR}/reuters-out ]; then
    if [ ! -e ${WORK_DIR}/reuters-sgm ]; then
      if [ ! -f ${WORK_DIR}/reuters21578.tar.gz ]; then
    if [ -n "$2" ]; then
        echo "Copying Reuters from local download"
        cp $2 ${WORK_DIR}/reuters21578.tar.gz
    else
              echo "Downloading Reuters-21578"
              curl http://kdd.ics.uci.edu/databases/reuters21578/reuters21578.tar.gz -o ${WORK_DIR}/reuters21578.tar.gz
    fi
      fi
      #make sure it was actually downloaded
      if [ ! -f ${WORK_DIR}/reuters21578.tar.gz ]; then
    echo "Failed to download reuters"
    exit 1
      fi
      mkdir -p ${WORK_DIR}/reuters-sgm
      echo "Extracting..."
      tar xzf ${WORK_DIR}/reuters21578.tar.gz -C ${WORK_DIR}/reuters-sgm
    fi
    echo "Extracting Reuters"
    mahout org.apache.lucene.benchmark.utils.ExtractReuters ${WORK_DIR}/reuters-sgm ${WORK_DIR}/reuters-out
    if [ "$HADOOP_HOME" != "" ] && [ "$MAHOUT_LOCAL" == "" ] ; then
        echo "Copying Reuters data to Hadoop"
        set +e
        $DFSRM ${WORK_DIR}/reuters-sgm
        $DFSRM ${WORK_DIR}/reuters-out
        $DFS -mkdir -p ${WORK_DIR}/
        $DFS -mkdir ${WORK_DIR}/reuters-sgm
        $DFS -mkdir ${WORK_DIR}/reuters-out
        $DFS -put ${WORK_DIR}/reuters-sgm ${WORK_DIR}/reuters-sgm
        $DFS -put ${WORK_DIR}/reuters-out ${WORK_DIR}/reuters-out
        set -e
    fi
  fi
  echo "Converting to Sequence Files from Directory"
  mahout seqdirectory -i ${WORK_DIR}/reuters-out -o ${WORK_DIR}/reuters-out-seqdir -c UTF-8 -chunk 64 -xm sequential
fi

  mahout seq2sparse \
    -i ${WORK_DIR}/reuters-out-seqdir/ \
    -o ${WORK_DIR}/reuters-out-seqdir-sparse-kmeans --maxDFPercent 85 --namedVector \
  && \
  mahout kmeans \
    -i ${WORK_DIR}/reuters-out-seqdir-sparse-kmeans/tfidf-vectors/ \
    -c ${WORK_DIR}/reuters-kmeans-clusters \
    -o ${WORK_DIR}/reuters-kmeans \
    -dm org.apache.mahout.common.distance.EuclideanDistanceMeasure \
    -x 10 -k 20 -ow --clustering \
  && \
  mahout clusterdump \
    -i `$DFS -ls -d ${WORK_DIR}/reuters-kmeans/clusters-*-final | awk '{print $8}'` \
    -o ${WORK_DIR}/reuters-kmeans/clusterdump \
    -d ${WORK_DIR}/reuters-out-seqdir-sparse-kmeans/dictionary.file-0 \
    -dt sequencefile -b 100 -n 20 --evaluate -dm org.apache.mahout.common.distance.EuclideanDistanceMeasure -sp 0 \
    --pointsDir ${WORK_DIR}/reuters-kmeans/clusteredPoints \
    && \
  cat ${WORK_DIR}/reuters-kmeans/clusterdump

  fi
