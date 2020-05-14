# HealthyLuncher-Demo

*HealthyLuncher* was created as a demo project for a [**CreateML blogpost**](https://www.netguru.co/codestories/createml-start-your-adventure-in-machine-learning-with-swift) and also used in [**On-Device Training with Core ML blog post**](https://www.netguru.com/codestories/on-device-training-with-core-ml-make-your-pancakes-healthy-again). 
It uses:
- **CoreML**
- **NaturalLanguage**
- **Vision**

frameworks in order to demonstrate Machine Learning models for image, text & data table classifications. 

### Images
HealthyLuncher enables us to predict based on the photo of the lunch whether it is healthy or not. Currently user can chose pictures only from the Photo Library for easier feature testing on the simulator.
<p align="center">
<img height="600" src="https://user-images.githubusercontent.com/18245585/47995944-3ecd8380-e0f7-11e8-9b16-93c2c8de0c63.gif"> 
</p>

### Text
User can also classify whether his lunch is healthy or not by typing his lunch in the text screen.
<p align="center">
<img height="600" src="https://user-images.githubusercontent.com/18245585/47995945-3ecd8380-e0f7-11e8-91b3-8e669b92bf40.gif">
</p>

### Data Table
The third data table screen demonstrates the Tabular Data classification.
<p align="center">
<img height="600" src="https://user-images.githubusercontent.com/18245585/47995946-3f661a00-e0f7-11e8-8fc5-bb6fc6bd1045.gif">
</p>

### On-Device Training
The new feature from Core ML is added for images section - updating the model. You can find detailed information in [On-Device Training with Core ML blog post](https://www.netguru.com/codestories/on-device-training-with-core-ml-make-your-pancakes-healthy-again).
<p align="center">
<img height="600" src="https://lh3.googleusercontent.com/tV7dDiCGrs8VO1ZutkNNpQ3RIb893wpktko23C-INFaiNYehiKsz6PNr9oPPcRqcKj23skLPZm86yjPxhxDmTwpfYjZ1Vvk2j2EflYSY-d8C1wa2MfZW4Q0eSAIjywVWRgOmZBhY">
</p>


## Tools
- Xcode 11.3

## Configuration
- Clone the repository
- Open .xcodeproj file and build the project

## Where To Go From Here
You can use *HealthyLuncher-Demo* for testing your Machine Lerning models.
Two things to keep in mind:
1) Add new models and change their names if neeeded in *ImageClassificationService*, *TextViewController* or *DataTableViewController*
2) Update class labels if needed in *Prediction.swift*
