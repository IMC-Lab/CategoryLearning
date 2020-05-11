var waitTime = 0; //30000;
var feedbackDelay = 0;
var feedbackDuration = 1000;
var studyDuration = 4000;
var studyITI = 1000;
var testITI = 1000;

function retry(promise, n, wait) {
    return promise.fail(function(error) {
        if (n === 1) throw error;
        return setTimeout(function () {
                            return retry(promise, n - 1, wait);
                          }, wait);
    });
}


function fetchJSON(filename) {
  return $.post('https://dibs-web01.vm.duke.edu/flower/CategoryLearning/experiments/mturk/get_json.php',
                {filename: filename})
          .then(function (data) { return JSON.parse(data); })
          .fail(function (jsonData, textStatus, error) {
                  throw "getJSON failed, filename: " + filename
                                + ", status: " + textStatus + ", error: " + error;
                });
}

function writeJSON(filename, data) {
  return $.post('https://dibs-web01.vm.duke.edu/flower/CategoryLearning/experiments/mturk/save_json.php',
                  // remove the web address for filename to save it locally
                {'filename': filename.replace('https://dibs-web01.vm.duke.edu/flower/CategoryLearning/experiments/mturk/', ''),
                 'data':JSON.stringify(data)})
            .fail(function (d, textStatus, error) {
              throw "POST json failed, status: " + textStatus + ", error: " + error;
            });
}

// Given this participant's feature assignment, get the next one.
function nextAssignmentDefault(oldAssignment, values) {
  let newAssignment = Object.assign({}, oldAssignment);
  let features = Object.keys(values);

  // try incrementing the value
  newAssignment.valueLearned = newAssignment.valueLearned + 1;

  // if we reached the last value for the feature than increment the feature
  if (newAssignment.valueLearned >= values[features[newAssignment.featureLearned]].length) {
    newAssignment.valueLearned = 0;
    newAssignment.featureLearned = newAssignment.featureLearned + 1;
  }

  // if we reached the last feature then reset to 0
  if (newAssignment.featureLearned >= features.length) {
    newAssignment.featureLearned = 0;
  }
  return newAssignment;
}

/*
 * Setup the html fields and links to run the experiment
 * experimentName- a string defining the name of the experiment, and what folder
 *                 to save behavioral data in.
 * assignmentFilename- the json file caching the current feature/value assignment
 * GetFilename- a function to get the filename of an image defined by a feature set
 * values- a mapping of feature names to all possible values for the feature
 * nLearning- number of learning trials
 * pLearnedLearning- percentage of stimuli in the learned category during learning
 * pFoilLearning- percentage of stimuli in the foil category during learning
 * nStudy- number of study trials
 * pLearnedStudy- percentage of stimuli in the learned category during study
 * pFoilStudy- percentage of stimuli in the foil category during study
 * nTest- number of test trials
 * pLearnedTest- percentage of lures in the learned category during test
 * pFoilTest- percentage of lures in the foil category during test
 * progressDir- the directory to save experiment progress information for multiple
 *              experiments. This is set to null by default, if only one experiment
 *              is being run.
 * learningFn- a function to run learning on button press
 * studyFn- a function to run study on button press
 * testFn- a function to run test on button press
 * saveFn- a function to save experient data on button press
 */
async function StartExperiment(experimentName, assignmentFilename, GetFilename, values,
                               nLearning, pLearnedLearning, pFoilLearning,
                               nLearningTest, pLearnedLearningTest, pFoilLearningTest,
                               nStudy, pLearnedStudy, pFoilStudy,
                               nTest, pLearnedTest, pFoilTest, nTestBlocks, dataDir='data', progressDir=null,
                               learningFn=null, learningTestFn=null, studyFn=null, testFn=null, saveFn=null,
                               nextAssignmentFn=null, confidence=false) {
   // Calculate the number of study/test stimuli in each block
   let studyBlockLength = Math.ceil(nStudy / nTestBlocks);
   let testBlockLength = Math.ceil(nTest / nTestBlocks);

  $('#numLearning').text(nLearning);
  $('#numLearningTest').text(nLearningTest);
  $('#numStudy').text(nStudy);
  $('#numStudyBlock').text(studyBlockLength);
  $('#numStudyBlocks').text(nTestBlocks);
  $('#totalStudyBlocks').text(nTestBlocks);
  $('#numStudyTest').text(studyBlockLength);
  $('#numTest').text(testBlockLength);
  $('#totalTestBlocks').text(nTestBlocks);
  $('#submitButton').hide();
  $('#startLearning').hide();

  let assignment = await fetchJSON(assignmentFilename);

  if (nextAssignmentFn) {
    await writeJSON(assignmentFilename, nextAssignmentFn(assignment, values));
  } else {
    await writeJSON(assignmentFilename, nextAssignmentDefault(assignment, values));
  }

  /* List of feature names */
  let features = Object.keys(values);
  // Set the learned category to the fetched feature and value
  let featureLearned = features[assignment.featureLearned];
  let valueLearned = values[featureLearned][assignment.valueLearned];

  // Set the foil category randomly
  let featureFoil = features[Math.floor(Math.random()*features.length)];
  while (featureLearned == featureFoil) {
    featureFoil = features[Math.floor(Math.random()*features.length)];
  }
  let valueFoil = values[featureFoil][Math.floor(Math.random()*values[featureFoil].length)];

  /* Build the lists of items to use for learning, study, and test */
  let itemsForLearning = CreateLearningList(nLearning, pLearnedLearning, pFoilLearning,
                                            values, featureLearned, valueLearned,
                                            featureFoil, valueFoil, GetFilename);
  let itemsForLearningTest = CreateLearningTestList(nLearningTest, itemsForLearning,
                                            pLearnedLearningTest, pFoilLearningTest,
                                            values, featureLearned, valueLearned,
                                            featureFoil, valueFoil, GetFilename);
  let itemsForStudy = CreateStudyList(nStudy, itemsForLearning, itemsForLearningTest,
                                      pLearnedStudy, pFoilStudy,
                                      values, featureLearned, valueLearned,
                                      featureFoil, valueFoil, GetFilename);
  let itemsForTest = CreateTestList(nTest, itemsForLearning, itemsForLearningTest,
                                    itemsForStudy, studyBlockLength, testBlockLength,
                                    pLearnedTest, pFoilTest, values,
                                    featureLearned, valueLearned,
                                    featureFoil, valueFoil, GetFilename);

  /* Set up button presses to their linked function */
  let stimuliType = experimentName.split("_")[0];
  if (document.getElementById('startLearning')) {
    document.getElementById('startLearning').onclick
      = (learningFn)? function() { learningFn(itemsForLearning, nLearningTest > 0); }
                    : function() { StartLearning(itemsForLearning, nLearningTest > 0); };
  }
  if (document.getElementById('startLearningTest')) {
    document.getElementById('startLearningTest').onclick
      = (learningTestFn)? function() { learningTestFn(itemsForLearning); }
                        : function() { StartLearningTest(itemsForLearningTest); };
  }
  if (document.getElementById('startStudy')) {
    document.getElementById('startStudy').onclick
      = (studyFn)? function() { studyFn(stimuliType, itemsForStudy, 0, studyBlockLength); }
                 : function() { StartStudy(stimuliType, itemsForStudy, 0, studyBlockLength); };
  }
  if (document.getElementById('startTest')) {
    document.getElementById('startTest').onclick
      = (testFn)? function () { testFn(stimuliType, itemsForTest, 0, testBlockLength, confidence); }
                : function () { StartTest(stimuliType, itemsForTest, 0, testBlockLength, confidence); };
  }
  if (document.getElementById('timSubmit')) {
    document.getElementById('timSubmit').onclick
      = (saveFn)? async function() {
                    saveFn(experimentName, dataDir, progressDir, featureLearned,
                           valueLearned, featureFoil, valueFoil,
                           itemsForLearning, itemsForLearningTest, itemsForStudy, itemsForTest);
                  }
                : async function() {
                    await SaveData(experimentName, dataDir, progressDir, featureLearned,
                                   valueLearned, featureFoil, valueFoil,
                                   itemsForLearning, itemsForLearningTest, itemsForStudy, itemsForTest);
                    // try to close the window after the data is saved.
                    if (window.opener) {
                       close();
                    }
                  };
  }

  if (document.getElementById('captchaSubmit')) {
    document.getElementById('captchaSubmit').onclick = async function() {
      $('#captchaBox').hide();
      $('#commentBox').show();
    }
  }

  return Object.assign(assignment,
         {'featureLearned':featureLearned,
          'valueLearned':valueLearned,
          'featureFoil':featureFoil,
          'valueFoil':valueFoil,
          'itemsForLearning':itemsForLearning,
          'itemsForLearningTest':itemsForLearningTest,
          'itemsForStudy':itemsForStudy,
          'itemsForTest':itemsForTest});
}

// Test for shallow object equality, since JSON.stringify doesn't seem to work
function ObjectEquals(obj1, obj2) {
  for (let k of Object.keys(obj1)) {
    if (obj1[k] != obj2[k]) {
      return false;
    }
  }

  for (let k of Object.keys(obj2)) {
    if (obj1[k] != obj2[k]) {
      return false;
    }
  }

  return true;
}

/* Check to see if obj is in array */
function ContainsObject(array, object) {
  for (let i=0; i < array.length; i++) {
    if (ObjectEquals(array[i].object, object)) {
      return true;
    }
  }

  return false;
}

/* Get an object that is either a member of the
   learned category or not; and a member of the foil
   category or not.
   values- the mapping from features to values
   featureLearned- the learned feature
   valueLearned- the value of the learned feature
   featureFoil- the foil feature
   valueFoil- the value of the unlearned feature
   */
function GetObject(values, featureLearned, valueLearned,
                   featureFoil, valueFoil) {
  let obj = {};
  for (let feature in values) {
    obj[feature] = values[feature][Math.floor(Math.random()*values[feature].length)];
  }

  obj[featureLearned] = valueLearned;
  obj[featureFoil] = valueFoil;
  return obj;
}

/*
 * Get an array of objects for this stage of the paradigm.
 * count- the number of objects to generate
 * stage- a string identifying the stage of the paradigm (learning, study, test)
 * htmlTag- where to store the image html src
 *
 * returns [objects, imageHTML]
 */
function GetObjects(count, values, featureLearned, valueLearned, featureFoil,
                    valueFoil, GetFilename, stage, pLearned, pFoil, avoidObjectsList) {
  let imageHTML = '';
  let index = 0;
  let items = [];
  let remainderItems = [];
  let pNotLearned = (1 - pLearned) / (values[featureLearned].length - 1);
  let pNotFoil = (1 - pFoil) / (values[featureFoil].length - 1);

  for (let i=0; i < values[featureLearned].length; i++) {
    for (let j=0; j < values[featureFoil].length; j++) {
      let isTarget = values[featureLearned][i] == valueLearned;
      let isFoil = values[featureFoil][j] == valueFoil;
      let n;
      if (isTarget && isFoil)
        n = pLearned * pFoil * count;
      else if (isTarget)
        n = pLearned * pNotFoil * count;
      else if (isFoil)
        n = pNotLearned * pFoil * count;
      else
        n = pNotLearned * pNotFoil * count;

      for (let k=0; k<n; k++) {
        // repeatedly set obj until it's not a duplicate
        let obj = GetObject(values, featureLearned, values[featureLearned][i],
                            featureFoil, values[featureFoil][j]);
        while (ContainsObject([...avoidObjectsList, ...items, ...remainderItems], obj)) {
          obj = GetObject(values, featureLearned, values[featureLearned][i],
                          featureFoil, values[featureFoil][j]);
        }

        let curItem = {'object': obj,
                       'filename': GetFilename(obj),
                       'isTarget': isTarget,
                       'isFoil': isFoil,
                       'id': stage + index};
        if (k < Math.floor(n)) {
          index++;
          items.push(curItem);
          imageHTML += '<img src="' + curItem.filename + '" id="' + curItem.id + '" class="categorizeImage">';
        } else {
          remainderItems.push(curItem);
        }
      }
    }
  }

  // add in the appropriate amount of remainder items
  while (items.length < count) {
    let curItem = remainderItems.splice(Math.floor(Math.random()*remainderItems.length), 1)[0];
    curItem.id = stage + index;
    index++;
    items.push(curItem);
    imageHTML += '<img src="' + curItem.filename + '" id="' + curItem.id + '" class="categorizeImage">';
  }

  return [items, imageHTML];
}


/* Create the set of objects to show in the learning phase */
function CreateLearningList(n, pLearned, pFoil, values, featureLearned,
                            valueLearned, featureFoil, valueFoil, GetFilename) {
  let [objects, imageHTML] = GetObjects(n, values, featureLearned, valueLearned,
                                        featureFoil, valueFoil, GetFilename, 'learn',
                                        pLearned, pFoil, []);
  $('#imagesForLearning').html(imageHTML);
  return Shuffle(objects);
}

/* Create the set of objects to show in the learning test phase */
function CreateLearningTestList(n, itemsForLearning, pLearned, pFoil, values, featureLearned,
                                valueLearned, featureFoil, valueFoil, GetFilename) {
  let [objects, imageHTML] = GetObjects(n, values, featureLearned, valueLearned,
                                        featureFoil, valueFoil, GetFilename, 'learnTest',
                                        pLearned, pFoil, [...itemsForLearning]);
  $('#imagesForLearningTest').html(imageHTML);
  return Shuffle(objects);
}

/* Create the set of objects to show in the study phase */
function CreateStudyList(n, itemsForLearning, itemsForLearningTest,
                         pLearned, pFoil, values, featureLearned,
                         valueLearned, featureFoil, valueFoil, GetFilename) {
  let [objects, imageHTML] = GetObjects(n, values, featureLearned, valueLearned,
                                        featureFoil, valueFoil, GetFilename, 'study',
                                        pLearned, pFoil, [...itemsForLearning, ...itemsForLearningTest]);
  $('#imagesForStudy').html(imageHTML);
  return Shuffle(objects);
}

/* Create the set of objects to show in the test phase */
function CreateTestList(nTest, itemsForLearning, itemsForLearningTest, itemsForStudy,
                        studyBlockLength, testBlockLength, pLearned, pFoil,
                        values, featureLearned, valueLearned, featureFoil,
                        valueFoil, GetFilename) {
  let nLures = nTest - itemsForStudy.length;
  let nBlocks = Math.ceil(nTest / testBlockLength);
  let lureBlockLength = testBlockLength - studyBlockLength;
  let [objects, imageHTML] = GetObjects(nLures, values, featureLearned, valueLearned,
                                        featureFoil, valueFoil, GetFilename, 'test',
                                        pLearned, pFoil, [...itemsForLearning, ...itemsForLearningTest, ...itemsForStudy]);
  Shuffle(objects);

  // set isOld to false
  for (let i=0; i<nLures; i++) {
    objects[i].isOld = false;
  }

  // arrange the lures into blocks
  var lures = [];
  for (let i=0; i<nBlocks; i++) {
    lures.push(objects.slice(i*lureBlockLength, (i+1)*lureBlockLength));
  }

  // Gather all of the old stimuli
  objects = [];
  for (let i=0; i<itemsForStudy.length; i++) {
    let curItemObj = itemsForStudy[i];
    let curItem = {'object': curItemObj.object,
                   'filename': curItemObj.filename,
                   'isTarget': curItemObj.isTarget,
                   'isFoil': curItemObj.isFoil,
                   'isOld': true,
                   'id': 'test' + (i + nLures)};
    objects.push(curItem);
    imageHTML += '<img src="' + curItem.filename + '" id="' + curItem.id + '" class="categorizeImage">';
  }

  // arrange the old stimuli into blocks
  var old = [];
  for (let i=0; i<nBlocks; i++) {
    old.push(objects.slice(i*studyBlockLength, (i+1)*studyBlockLength));
  }

  // Merge all of the lures and old stimuli by block
  objects = [];
  for (let i=0; i<lures.length; i++) {
    objects = objects.concat(Shuffle([...old[i], ...lures[i]]));
  }

  $('#imagesForTest').html(imageHTML);
  return objects;
}


/* LEARNING TASK ------------------------------------------------- */
function StartLearning(stimuli, learningTest) {
  if (IsOnTurk() && IsTurkPreview()) {
    alert('Please accept the HIT before beginning!');
    return;
  }
  $('#categoryInstruc1').hide();
  $('#instrucBox').show();
  $('#experimentBox').show();
  NextTrialLearning(0, stimuli, learningTest);
}

function NextTrialLearning(curTrial, stimuli, learningTest) {
  $('#trialCnt').text("Trial " + (curTrial+1) + " of " + stimuli.length);
  $('#' + stimuli[curTrial].id).show();
  let startTrialTime = (new Date()).getTime();
  setTimeout(function() {
    $(document).bind('keyup', 'y', function() {
      ResponseLearning(stimuli[curTrial].isTarget, curTrial, stimuli, learningTest, startTrialTime);
    });
    $(document).bind('keyup', 'n', function() {
      ResponseLearning(!stimuli[curTrial].isTarget, curTrial, stimuli, learningTest, startTrialTime);
    });
   }, 200);
}

function ResponseLearning(correct, curTrial, stimuli, learningTest, startTrialTime) {
  let curTrialItem = stimuli[curTrial];
  curTrialItem['wasCorrect'] = correct;
  curTrialItem['RT'] = (new Date()).getTime() - startTrialTime;
	$(document).unbind('keyup');
  setTimeout(function() {
    $('#' + curTrialItem.id).hide();
    if (correct) {
      $('#correct').show();
    } else {
      $('#wrong').show();
    }

    setTimeout(function() {
     $('#correct').hide();
     $('#wrong').hide();

     if (curTrial<stimuli.length-1) {
       NextTrialLearning(curTrial+1, stimuli, learningTest);
     } else if (learningTest) {
       ShowLearningTestStart();
     } else {
       ShowStudyStart();
     }
   }, feedbackDuration);
 }, feedbackDelay);
}

/* LEARNING TEST TASK ------------------------------------------------- */
function ShowLearningTestStart() {
  $('#instrucBox').hide();
  $('#instrucTextCur').html('Do you think this is an avlonia? <b>(y/n)</b>');
  $('#experimentBox').hide();
  $('#startLearningTest').hide();
  $('#learnTestInstruc').show();
  setTimeout(function () {
    $('#loadingLearningTest').hide();
    $('#startLearningTest').show();
  }, waitTime);
}

function StartLearningTest(stimuli) {
  $('#instrucBox').show();
  $('#experimentBox').show();
  //$('.categorizeImage').hide();
  $('#learnTestInstruc').hide();

  $('#instrucBox').show();
  $('#experimentBox').show();
  NextTrialLearningTest(0, stimuli);
}

function NextTrialLearningTest(curTrial, stimuli) {
  $('#trialCnt').text("Trial " + (curTrial+1) + " of " + stimuli.length);
  $('#' + stimuli[curTrial].id).show();
  let startTrialTime = (new Date()).getTime();
  setTimeout(function() {
    $(document).bind('keyup', 'y', function() {
      ResponseLearningTest(stimuli[curTrial].isTarget, curTrial, stimuli, startTrialTime);
    });
    $(document).bind('keyup', 'n', function() {
      ResponseLearningTest(!stimuli[curTrial].isTarget, curTrial, stimuli, startTrialTime);
    });
   }, 200);
}

function ResponseLearningTest(correct, curTrial, stimuli, startTrialTime) {
  let curTrialItem = stimuli[curTrial];
  curTrialItem['wasCorrect'] = correct;
  curTrialItem['RT'] = (new Date()).getTime() - startTrialTime;
	$(document).unbind('keyup');
  $('#' + curTrialItem.id).hide();

  if (curTrial<stimuli.length-1) {
    NextTrialLearningTest(curTrial+1, stimuli);
  } else {
    ShowStudyStart();
  }
}

/* STUDY TASK ------------------------------------------------- */
function ShowStudyStart() {
  $('#instrucBox').hide();
  $('#experimentBox').hide();
  $('#startStudy').hide();
  $('#studyInstruc').show();
  setTimeout(function () {
    $('#loadingStudy').hide();
    $('#startStudy').show();
  }, waitTime);
  $('#instrucTextCur').html("&nbsp; &nbsp;");
}

function StartStudy(stimuliType, stimuli, blockNumber, blockLength) {
  $('#instrucTextCur').text("Remember these " + blockLength + " "
                            + stimuliType.toLowerCase() + "s!");
  $('#instrucBox').show();
  $('#experimentBox').show();
  $('.categorizeImage').hide();
  $('#studyInstruc').hide();

  // Reset the study link to go the next block next time around
  document.getElementById('startStudy').onclick
    = function() { StartStudy(stimuliType, stimuli, blockNumber+1, blockLength); };
  $('#studyCompletion').text("You've completed block " + (blockNumber+1) + " of " + Math.ceil(stimuli.length / blockLength) + ".");
  $('#testCompletion').text("You've studied block " + (blockNumber+1) + " of " + Math.ceil(stimuli.length / blockLength) + ".");
  $('#curStudyBlock').text(blockNumber+2);

  stimuliType = stimuliType.charAt(0).toUpperCase() + stimuliType.toLowerCase().slice(1);
  NextTrialStudy(0, stimuliType, stimuli, blockNumber, blockLength);
}

function NextTrialStudy(curTrial, stimuliType, stimuli, blockNumber, blockLength) {
  let curID = '#' + stimuli[curTrial + blockNumber * blockLength].id;
  $('#trialCnt').text(stimuliType + " " + (curTrial+1) + " of " + blockLength +
    ', Block ' + (blockNumber+1) + ' of ' + Math.ceil(stimuli.length / blockLength));
  $(curID).show();
  setTimeout(function() {
    $(curID).hide();
    setTimeout(function() {
      if (curTrial < blockLength-1) {
        NextTrialStudy(curTrial+1, stimuliType, stimuli, blockNumber, blockLength);
      } else {
        StartMemoryTest();
      }
    }, studyITI);
  }, studyDuration);
}

/* MEMORY TEST TASK ------------------------------------------------- */
function StartMemoryTest() {
  $('#instrucBox').hide();
  $('#experimentBox').hide();
  $('#testInstruc').show();
  $('#instrucTextCur').html("&nbsp; &nbsp;");
  $('#startTest').hide();
  setTimeout(function () {
    $('#loadingTest').hide();
    $('#startTest').show();
  }, waitTime);
}

function StartTest(stimuliType, stimuli, blockNumber, blockLength, confidence) {
  $('#testInstruc').hide();
  $('#instrucTextCur').html("Did you see this " + stimuliType + " earlier? <b>(y/n)</b>");
  $('#instrucBox').show();
  $('#experimentBox').show();
  $('.categorizeImage').hide();

  // Reset the study link to go the next block next time around
  document.getElementById('startTest').onclick
    = function() { StartTest(stimuliType, stimuli, blockNumber+1, blockLength, confidence); };
  $('#curTestBlock').text(blockNumber+2);

  NextTrialTest(0, stimuliType, stimuli, blockNumber, blockLength, confidence);
}

function NextTrialTest(curTrial, stimuliType, stimuli, blockNumber, blockLength, confidence) {
  let curTrialItem = stimuli[curTrial + blockNumber * blockLength];
  $('.categorizeImage').hide();
  $('#instrucTextCur').html("Did you see this " + stimuliType + " earlier? <b>(y/n)</b>");
  $('#trialCnt').text("Trial " + (curTrial+1) + " of " + blockLength +
    ', Block ' + (blockNumber+1) + ' of ' + Math.ceil(stimuli.length / blockLength));
  $('#' + curTrialItem.id).show();

  let startTrialTime = (new Date()).getTime();
  setTimeout(function() {
    $(document).bind('keyup', 'y', function() {
      ResponseTest(curTrialItem.isOld, curTrial, stimuliType, stimuli, blockNumber, blockLength, startTrialTime, confidence);
    });
    $(document).bind('keyup', 'n', function() {
      ResponseTest(!curTrialItem.isOld, curTrial, stimuliType, stimuli, blockNumber, blockLength, startTrialTime, confidence);
    });
   }, 300);
}

function ResponseTest(correct, curTrial, stimuliType, stimuli, blockNumber, blockLength, startTrialTime, confidence) {
  let curTrialItem = stimuli[curTrial + blockNumber * blockLength];
  curTrialItem['wasCorrect'] = correct;
  curTrialItem['RT'] = (new Date()).getTime() - startTrialTime;
	$(document).unbind('keyup');

  // if recording confidence ratings, break to there
  if (confidence) {
    NextConfidenceTrialTest(curTrial, stimuliType, stimuli, blockNumber, blockLength);
    return;
  }

  $('#' + curTrialItem.id).hide();
  setTimeout(function() {
    if (curTrial < blockLength - 1) {
      NextTrialTest(curTrial+1, stimuliType, stimuli, blockNumber, blockLength, confidence);
    } else if (blockNumber < Math.ceil(stimuli.length / blockLength) - 1) {
      ShowStudyStart();
    } else {
      ShowDone(stimuli);
    }
  }, testITI);
}

function NextConfidenceTrialTest(curTrial, stimuliType, stimuli, blockNumber, blockLength) {
  $('#instrucTextCur').html("How confident are you? <b>(1-7)</b>");

  let startTrialTime = (new Date()).getTime();
  setTimeout(function() {
    for (let i=1; i<=7; i++) {
      $(document).bind('keyup', i.toString(), function() {
        ConfidenceResponseTest(i, curTrial, stimuliType, stimuli, blockNumber, blockLength, startTrialTime);
      });
    }
   }, 300);
}

function ConfidenceResponseTest(confidenceRating, curTrial, stimuliType, stimuli, blockNumber, blockLength, startTrialTime) {
  let curTrialItem = stimuli[curTrial + blockNumber * blockLength];
  curTrialItem['confidence'] = confidenceRating;
  curTrialItem['confidenceRT'] = (new Date()).getTime() - startTrialTime;
  $(document).unbind('keyup');

  $('#' + curTrialItem.id).hide();
  setTimeout(function() {
    if (curTrial < blockLength - 1) {
      NextTrialTest(curTrial+1, stimuliType, stimuli, blockNumber, blockLength, true);
    } else if (blockNumber < Math.ceil(stimuli.length / blockLength) - 1) {
      ShowStudyStart();
    } else {
      ShowDone(stimuli);
    }
  }, testITI);
}


/* DONE ------------------------------------------------- */
function ShowDone(itemsForTest) {
  let correctCount = 0;
  for (let i=0; i<itemsForTest.length; ++i) {
    if (itemsForTest[i]['wasCorrect'])
      correctCount++;
  }

  $('#instrucTextCur').html("&nbsp; &nbsp;");
  $('#numRight').text(correctCount);
  $('#numTotal').text(itemsForTest.length);
  $('#done').show();
}

async function ShowNextExperiment(progressFilename) {
  let progress;
  try {
    // wait for a second just to make sure the progress has been updated
    progress = await retry(fetchJSON(progressFilename), 10, 75);
  } catch (error) {
    return false;
  }

  let totalExps = progress['numExperiments'];
  let curExp = progress['curExperiment'];
  // hide the links for all experiments
  for (let i = 1; i <= totalExps; ++i) {
    $('#experiment' + i).hide();
  }

  // show the link for the current experiment
  if (curExp <= totalExps) {
    $('#experiment' + curExp).show();
  } else {
    $('#done').show();
  }

  // return true if done
  return curExp > totalExps;
}

/*
 * Look for the var curID in the parent window (if this tab was opened by another tab).
 * If that isn't set, look for curID in this window.
 * Else, prompt the user for an ID until they give a non-empty response.
 */
function GetID(event) {
  let id;
  try {
   id = (window.opener)? window.opener.curID : curID;
  } catch (error) { id = null; }

  while (!id || id === "") {
    id = (IsOnTurk())? GetAssignmentId() : prompt('Please enter your mTurk ID:','');
  }
  return id;
}

async function SaveData(experimentName, dataDir, progressDir, featureLearned, valueLearned,
                        featureFoil, valueFoil, itemsForLearning,
                        itemsForLearningTest, itemsForStudy, itemsForTest) {
  $('#done').hide();
  $('#saving').show();

  let correctRate = parseFloat($('#numRight').text(), 10) / itemsForTest.length;
  let earnedBonus = correctRate >= 0.85;
  let curID = GetID();
  let progress;
  if (progressDir) {
    progress = await fetchJSON(progressDir + curID + '.json');
    progress['curExperiment'] = progress['curExperiment'] + 1;
    await writeJSON(progressDir + curID + '.json', progress);
  } else {
    progress = {'curExperiment':1, 'numExperiments':1};
  }

  Save("experimentNumber", progress['curExperiment']);
  Save("correctRate", correctRate);
  Save("earnedBonus", earnedBonus);
  Save("featuredLearned", featureLearned);
  Save("featureFoil", featureFoil);
  Save("valueLearned", valueLearned);
  Save("valueFoil", valueFoil);

  for (let i=0; i<itemsForLearning.length; i++) {
    Save(itemsForLearning[i].id, itemsForLearning[i]);
  }
  for (let i=0; i<itemsForLearningTest.length; i++) {
    Save(itemsForLearningTest[i].id, itemsForLearningTest[i]);
  }
  for (let i=0; i<itemsForStudy.length; i++) {
    Save(itemsForStudy[i].id, itemsForStudy[i]);
  }
  for (let i=0; i<itemsForTest.length; i++) {
    Save(itemsForTest[i].id, itemsForTest[i]);
  }
  Save("userAgent", navigator.userAgent);
  Save("windowWidth", $(window).width());
  Save("windowHeight", $(window).height());
  Save("screenWidth", screen.width);
  Save("screenHeight", screen.height);

  let newDate = new Date();
  let d = {
    "curID": curID,
    "curTime": newDate.today() + " @ " + newDate.timeNow(),
    "userAgent": navigator.userAgent,
    "windowWidth": $(window).width(),
    "windowHeight": $(window).height(),
    "screenWidth": screen.width,
    "screenHeight": screen.height,
    "comments": $('#comments').val(),
    "captcha": $('#captcha').val(),
    "experimentNumber": progress['curExperiment'],
    "correctRate": correctRate,
    "earnedBonus": earnedBonus,
    "featureLearned": featureLearned,
    "featureFoil": featureFoil,
    "valueLearned": valueLearned,
    "valueFoil": valueFoil,
    "itemsForLearning": itemsForLearning,
    "itemsForLearningTest": itemsForLearningTest,
    "itemsForStudy": itemsForStudy,
    "itemsForTest": itemsForTest
  };

  return SendToServer(curID, d, experimentName, dataDir);
}

function Save(name, content) {
  $('#instrucBox').append(
    "<input type='hidden' name='" + name + "' value='" + JSON.stringify(content) + "'>");
}

function SendToServer(id, curData, experimentName, dataDir) {
  console.log('Saving to: ' + dataDir + '/' + experimentName + '/' + id + '.txt');
  let dataToServer = {
    'id': id,
    'directory': dataDir,
    'experimentName': experimentName,
    'curData': JSON.stringify(curData)
  };

  return $.post("https://dibs-web01.vm.duke.edu/flower/CategoryLearning/experiments/mturk/save.php",
                dataToServer,
                function(data) {
                  if (IsOnTurk()) {
                    document.forms[0].submit();
                  } else {
                    $('#saving').hide();
                  }
                }).fail(function(data) {
                          console.log("POST FAILED");
                          if (IsOnTurk()) {
                            document.forms[0].submit();
                          } else {
                            $('#saving').hide();
                          }
                      }).promise();
}
