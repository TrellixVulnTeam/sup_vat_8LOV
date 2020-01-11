#!/usr/bin/env bash
gpu=$1
adv_weight=$2

set -e
time=$(date +'%m%d_%H:%M')
gitcommit_number=$(git rev-parse HEAD)
gitcommit_number=${gitcommit_number:0:8}

max_peoch=120
data_aug=PILaugment
net=enet
logdir=GM/weight_search/$net"_adv_weigth_check${adv_weight}"
tqdm=False
augment_labeled_data=True
augment_unlabeled_data=True
seed=1

source utils.sh

Summary(){
set -e
subfolder=$1
gpu=$2
echo CUDA_VISIBLE_DEVICES=$gpu python Summary.py --input_dir runs/$logdir/$subfolder --dataset=GM --kappa_considered_class 0 1
CUDA_VISIBLE_DEVICES=$gpu python Summary.py --input_dir runs/$logdir/$subfolder --dataset=GM --kappa_considered_class 0 1
}

FS(){
set -e
gpu=$1
currentfoldername=FS
rm -rf runs/$logdir/$currentfoldername
CUDA_VISIBLE_DEVICES=$gpu python train_ACDC_cotraining.py Trainer.save_dir=runs/$logdir/$currentfoldername \
Trainer.max_epoch=$max_peoch Trainer.axises=[0,1] \
Dataset.augment=$data_aug Dataset.transform="segment_transform((200,200))" \
StartTraining.train_adv=False StartTraining.train_jsd=False \
Lab_Partitions.num_models=2 \
Lab_Partitions.partition_overlap=1 \
Arch.name=$net Arch.num_classes=2 Trainer.use_tqdm=$tqdm \
Dataset.root_dir=dataset/GM_Challenge \
Adv_Scheduler.max_value=$adv_weight \
StartTraining.augment_labeled_data=$augment_labeled_data \
StartTraining.augment_unlabeled_data=$augment_unlabeled_data \
Seed=$seed
Summary $currentfoldername $gpu
rm -rf archives/$logdir/$currentfoldername
mv -f runs/$logdir/$currentfoldername archives/$logdir
}

JSD(){
set -e
gpu=$1
currentfoldername=JSD
rm -rf runs/$logdir/$currentfoldername
CUDA_VISIBLE_DEVICES=$gpu python train_ACDC_cotraining.py Trainer.save_dir=runs/$logdir/$currentfoldername \
Trainer.max_epoch=$max_peoch Trainer.axises=[0,1] \
Dataset.augment=$data_aug Dataset.transform="segment_transform((200,200))" \
StartTraining.train_adv=False StartTraining.train_jsd=True \
Lab_Partitions.num_models=2 \
Lab_Partitions.partition_overlap=1 \
Arch.name=$net Arch.num_classes=2 Trainer.use_tqdm=$tqdm \
Dataset.root_dir=dataset/GM_Challenge \
Adv_Scheduler.max_value=$adv_weight \
StartTraining.augment_labeled_data=$augment_labeled_data \
StartTraining.augment_unlabeled_data=$augment_unlabeled_data \
Seed=$seed
Summary $currentfoldername $gpu
rm -rf archives/$logdir/$currentfoldername
mv -f runs/$logdir/$currentfoldername archives/$logdir
}

ADV(){
set -e
gpu=$1
currentfoldername=ADV
rm -rf runs/$logdir/$currentfoldername
CUDA_VISIBLE_DEVICES=$gpu python train_ACDC_cotraining.py Trainer.save_dir=runs/$logdir/$currentfoldername \
Trainer.max_epoch=$max_peoch Trainer.axises=[0,1] \
Dataset.augment=$data_aug Dataset.transform="segment_transform((200,200))" \
StartTraining.train_adv=True StartTraining.train_jsd=False \
Lab_Partitions.num_models=2 \
Lab_Partitions.partition_overlap=1 \
Arch.name=$net Arch.num_classes=2 Trainer.use_tqdm=$tqdm \
Dataset.root_dir=dataset/GM_Challenge \
Adv_Scheduler.max_value=$adv_weight \
StartTraining.augment_labeled_data=$augment_labeled_data \
StartTraining.augment_unlabeled_data=$augment_unlabeled_data \
Seed=$seed
Summary $currentfoldername $gpu
rm -rf archives/$logdir/$currentfoldername
mv -f runs/$logdir/$currentfoldername archives/$logdir
}

JSD_ADV(){
set -e
gpu=$1
currentfoldername=JSD_ADV
rm -rf runs/$logdir/$currentfoldername
echo CUDA_VISIBLE_DEVICES=$gpu python train_ACDC_cotraining.py Trainer.save_dir=runs/$logdir/$currentfoldername \
Trainer.max_epoch=$max_peoch Trainer.axises=[0,1] \
Dataset.augment=$data_aug Dataset.transform="segment_transform((200,200))" \
StartTraining.train_adv=True StartTraining.train_jsd=True \
Lab_Partitions.num_models=2 \
Lab_Partitions.partition_overlap=1 \
Arch.name=$net Arch.num_classes=2 Trainer.use_tqdm=$tqdm \
Dataset.root_dir=dataset/GM_Challenge \
Adv_Scheduler.max_value=$adv_weight \
StartTraining.augment_labeled_data=$augment_labeled_data \
StartTraining.augment_unlabeled_data=$augment_unlabeled_data \
Seed=$seed
CUDA_VISIBLE_DEVICES=$gpu python train_ACDC_cotraining.py Trainer.save_dir=runs/$logdir/$currentfoldername \
Trainer.max_epoch=$max_peoch Trainer.axises=[0,1] \
Dataset.augment=$data_aug Dataset.transform="segment_transform((200,200))" \
StartTraining.train_adv=True StartTraining.train_jsd=True \
Lab_Partitions.num_models=2 \
Lab_Partitions.partition_overlap=1 \
Arch.name=$net Arch.num_classes=2 Trainer.use_tqdm=$tqdm \
Dataset.root_dir=dataset/GM_Challenge \
Adv_Scheduler.max_value=$adv_weight \
StartTraining.augment_labeled_data=$augment_labeled_data \
StartTraining.augment_unlabeled_data=$augment_unlabeled_data \
Seed=$seed
Summary $currentfoldername $gpu
rm -rf archives/$logdir/$currentfoldername
mv -f runs/$logdir/$currentfoldername archives/$logdir
}

cd ../..
#rm -rf archives/$logdir
mkdir -p archives/$logdir
#rm -rf runs/$logdir
mkdir -p runs/$logdir


JSD_ADV $gpu &
FS $gpu &
wait_script

ADV $gpu &
JSD $gpu &
wait_script


#python generalframework/postprocessing/plot.py --folders archives/$logdir/FS/ \
# archives/$logdir/PS/ \
#archives/$logdir/JSD/  archives/$logdir/ADV/ archives/$logdir/JSD_ADV/ --file val_dice.npy --axis 1 2 3 --postfix=model0 --seg_id=0 --y_lim 0.3 0.9
#
#python generalframework/postprocessing/plot.py --folders archives/$logdir/FS/ \
# archives/$logdir/PS/ \
#archives/$logdir/JSD/  archives/$logdir/ADV/ archives/$logdir/JSD_ADV/  --file val_dice.npy --axis 1 2 3 --postfix=model1 --seg_id=1 --y_lim 0.3 0.9

python generalframework/postprocessing/report.py --folder=archives/$logdir/ --file=summary.csv
#
zip -rq archives/$logdir"_"$time"_"$gitcommit_number".zip" archives/$logdir
rm -rf runs/$logdir
