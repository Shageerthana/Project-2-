unzip('R_allfruits.zip');
imds = imageDatastore('R_allfruits', ...
    'IncludeSubfolders',true, ...
    'LabelSource','foldernames');
%split the data into training 70% and validation 30%
[imdsTrain,imdsValidation] = splitEachLabel(imds,0.7,'randomized');

%loading the pre -trained network 
net = alexnet;
%analyze the network 
analyzeNetwork(net)
%first layer with the input images with a specific size
inputSize = net.Layers(1).InputSize
%tuning the last 3 layers of the network
layersTransfer = net.Layers(1:end-3);
%replacing the last 3 layers - fully connected layer, softmax layer,
%classification output layer
numClasses = numel(categories(imdsTrain.Labels))
layers = [
    layersTransfer
    fullyConnectedLayer(numClasses,'WeightLearnRateFactor',20,'BiasLearnRateFactor',20)
    softmaxLayer
    classificationLayer];

%training the network - making the augmented image datastore 
pixelRange = [-30 30];
imageAugmenter = imageDataAugmenter( ...
    'RandXReflection',true, ...
    'RandXTranslation',pixelRange, ...
    'RandYTranslation',pixelRange);
augimdsTrain = augmentedImageDatastore(inputSize(1:2),imdsTrain, ...
    'DataAugmentation',imageAugmenter);
%validating the images using the augmented datastore 
augimdsValidation = augmentedImageDatastore(inputSize(1:2),imdsValidation);

options = trainingOptions('sgdm', ...
    'MiniBatchSize',200, ...
    'MaxEpochs',10, ...
    'InitialLearnRate',1e-4, ...
    'Shuffle','every-epoch', ...
    'ValidationData',augimdsValidation, ...
    'ValidationFrequency',5, ...
    'Verbose',false, ...
    'Plots','training-progress');

netTransfer = trainNetwork(augimdsTrain,layers,options);

%classification of validation images 
[YPred,scores] = classify(netTransfer,augimdsValidation);
Yvalidation = imdsValidation.Labels;

%plot confusion matrix 
%figure,
%plotconfusion(Yvalidation,YPred)    
