var waitTime = 90000;

function retry(promise, n, wait) {
    return promise.fail(function(error) {
        if (n === 1) throw error;
        return setTimeout(function () {
                            return retry(promise, n - 1, wait);
                          }, wait);
    });
}


function fetchJSON(filename) {
  return $.getJSON(filename)
          .done(function (jsonData) {
            return jsonData;
          }).fail(function (jsonData, textStatus, error) {
            throw "getJSON failed, filename: " + filename
                          + ", status: " + textStatus + ", error: " + error;
          });
}

function writeJSON(filename, data) {
  return $.post('http://web-mir.ccn.duke.edu/flower/save_json.php',
                {'filename': filename,
                 'data':JSON.stringify(data)})
            .fail(function (d, textStatus, error) {
              throw "POST json failed, status: " + textStatus + ", error: " + error;
            });
}

// Given this participant's feature assignment, get the next one.
function nextAssignment(oldAssignment, values) {
  let newAssignment = Object.assign({}, oldAssignment);
  let features = Object.keys(values);

  // try incrementing the value
  newAssignment.valueLearned = newAssignment.valueLearned + 1;

  // if we reached the last value for the feature than increment the feature
  if (newAssignment.valueLearned >= values[features[newAssignment.featureLearned]].length) {
    newAssignment.valueLearned = 0;
    newAssignment.featureLearned = newAssignment.featureLearned + 1;
  }

  // if we reached the last feature than reset to 0
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
                               nStudy, pLearnedStudy, pFoilStudy,
                               nTest, pLearnedTest, pFoilTest, dataDir='data', progressDir=null,
                               learningFn=null, studyFn=null, testFn=null, saveFn=null) {
  $('#numLearning').text(nLearning);
  $('#numStudy').text(nStudy);
  $('#numTest').text(nTest);
  $('#submitButton').hide();
  $('#startLearning').hide()

  let assignment = await fetchJSON(assignmentFilename);
  await writeJSON(assignmentFilename, nextAssignment(assignment, values));

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

  /* For now, output the learned features */
  /*
  console.log('learned feature: ' + featureLearned);
  console.log('learned value: ' + valueLearned);
  console.log('unlearned feature: ' + featureFoil);
  console.log('unlearned value: ' + valueFoil);
  */

  /* Build the lists of items to use for learning, study, and test */
  let itemsForLearning = CreateLearningList(nLearning, pLearnedLearning, pFoilLearning,
                                            values, featureLearned, valueLearned,
                                            featureFoil, valueFoil, GetFilename);
  let itemsForStudy = CreateStudyList(nStudy, itemsForLearning, pLearnedStudy, pFoilStudy,
                                      values, featureLearned, valueLearned,
                                      featureFoil, valueFoil, GetFilename);
  let itemsForTest = CreateTestList(nTest, itemsForLearning, itemsForStudy,
                                    pLearnedTest, pFoilTest, values,
                                    featureLearned, valueLearned,
                                    featureFoil, valueFoil, GetFilename);

  /* Set up button presses to their linked function */
  let stimuliType = experimentName.split("_")[0];
  document.getElementById('startLearning').onclick
    = (learningFn)? function() { learningFn(itemsForLearning); }
                  : function() { StartLearning(itemsForLearning); };
  document.getElementById('startStudy').onclick
    = (studyFn)? function() { studyFn(stimuliType, itemsForStudy); }
               : function() { StartStudy(stimuliType, itemsForStudy); };
  document.getElementById('startTest').onclick
    = (testFn)? function () { testFn(stimuliType, itemsForTest); }
              : function () { StartTest(stimuliType, itemsForTest); };
  document.getElementById('timSubmit').onclick
    = (saveFn)? async function() {
                  saveFn(experimentName, featureLearned, valueLearned,
                         featureFoil, valueFoil, itemsForLearning,
                         itemsForStudy, itemsForTest);
                }
              : async function() {
                  await SaveData(experimentName, dataDir, progressDir, featureLearned,
                                 valueLearned, featureFoil, valueFoil,
                                 itemsForLearning, itemsForStudy, itemsForTest);

                  // try to close the window after the data is saved.
                  if (window.opener) {
                     close();
                  }
                };

  // After 90s show the link to continue
  setTimeout(function () {
      $('#loadingLearning').hide();
      $('#startLearning').show();
  }, waitTime);
}

/* Get an object that is either a member of the
   learned category or not; and a member of the foil
   category or not. Make sure the new object does
   not equal any of the objects in avoidObjectsList
   values- the mapping from features to values
   featureLearned- the learned feature
   valueLearned- the value of the learned feature
   featureFoil- the foil feature
   valueFoil- the value of the unlearned feature
   */
function GetObject(values, featureLearned, valueLearned,
                   featureFoil, valueFoil, avoidObjectsList) {
  let avoidObjects = new Array();
  for (let i=0; i<avoidObjectsList.length; i++) {
    avoidObjects.push.apply(avoidObjects, avoidObjectsList[i]);
  }

  let obj = {};
  for (let feature in values) {
    obj[feature] = values[feature][Math.floor(Math.random()*3)];
  }

  obj[featureLearned] = valueLearned;
  obj[featureFoil] = valueFoil;

  /* Check to see if it matches anything we are supposed to avoid */
  let overlaps = false;
  for (let i=0; i<avoidObjects.length; i++) {
    if (JSON.stringify(avoidObjects[i].object)===JSON.stringify(obj)) {
      overlaps = true;
      break;
    }
  }

  /* If it does match an object we want to avoid, recurse to generate a new object: */
  return (overlaps)? GetObject(values, featureLearned, valueLearned,
                               featureFoil, valueFoil, avoidObjectsList) : obj;
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
        let obj = GetObject(values, featureLearned, values[featureLearned][i],
                            featureFoil, values[featureFoil][j], [...avoidObjectsList, ...items]);
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

/* Create the set of objects to show in the study phase */
function CreateStudyList(n, itemsForLearning, pLearned, pFoil, values, featureLearned,
                         valueLearned, featureFoil, valueFoil, GetFilename) {
  let [objects, imageHTML] = GetObjects(n, values, featureLearned, valueLearned,
                                        featureFoil, valueFoil, GetFilename, 'study',
                                        pLearned, pFoil, [...itemsForLearning]);
  $('#imagesForStudy').html(imageHTML);
  return Shuffle(objects);
}

/* Create the set of objects to show in the test phase */
function CreateTestList(nTest, itemsForLearning, itemsForStudy, pLearned, pFoil,
                        values, featureLearned, valueLearned, featureFoil,
                        valueFoil, GetFilename) {
  let nLures = nTest - itemsForStudy.length;
  let [objects, imageHTML] = GetObjects(nLures, values, featureLearned, valueLearned,
                                        featureFoil, valueFoil, GetFilename, 'test',
                                        pLearned, pFoil, [...itemsForLearning, ...itemsForStudy]);
  // set isOld to false
  for (let i=0; i<nLures; i++) {
    objects[i].isOld = false;
  }

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

  $('#imagesForTest').html(imageHTML);
  return Shuffle(objects);
}


/* LEARNING TASK ------------------------------------------------- */
function StartLearning(itemsForLearning) {
  if (IsOnTurk() && IsTurkPreview()) {
    alert('Please accept the HIT before beginning!');
    return;
  }
  $('#categoryInstruc1').hide();
  $('#instrucBox').show();
  $('#experimentBox').show();
  NextTrialLearning(0, itemsForLearning);
}

function NextTrialLearning(curTrial, itemsForLearning) {
  $('#trialCnt').text("Trial " + (curTrial+1) + " of " + itemsForLearning.length);
  $('#' + itemsForLearning[curTrial].id).show();
  let startTrialTime = (new Date()).getTime();
  setTimeout(function() {
    $(document).bind('keyup', 'y', function(){PressedYesLearning(curTrial, itemsForLearning, startTrialTime);});
    $(document).bind('keyup', 'n', function(){PressedNoLearning(curTrial, itemsForLearning, startTrialTime);});
   }, 200);
}

function PressedYesLearning(curTrial, itemsForLearning, startTrialTime) {
  ResponseLearning(itemsForLearning[curTrial].isTarget, curTrial,
                   itemsForLearning, startTrialTime);
}

function PressedNoLearning(curTrial, itemsForLearning, startTrialTime) {
  ResponseLearning(!itemsForLearning[curTrial].isTarget, curTrial,
                   itemsForLearning, startTrialTime);
}

function ResponseLearning(correct, curTrial, itemsForLearning, startTrialTime) {
  let curTrialItem = itemsForLearning[curTrial];
  $('#' + curTrialItem.id).hide();
  curTrialItem['wasCorrect'] = correct;
  curTrialItem['RT'] = (new Date()).getTime() - startTrialTime;
	$(document).unbind('keyup');

  if (correct) {
    $('#correct').show();
  } else {
    $('#wrong').show();
  }


  setTimeout(function() {
   $('#correct').hide();
   $('#wrong').hide();

   if (curTrial<itemsForLearning.length-1) {
     NextTrialLearning(curTrial+1, itemsForLearning);
   } else {
     ShowStudyStart();
   }
  }, 1000);
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

function StartStudy(stimuliType, itemsForStudy) {
  $('#instrucTextCur').text("Remember these " + itemsForStudy.length + " "
                            + stimuliType.toLowerCase() + "s as best you can!");
  $('#instrucBox').show();
  $('#experimentBox').show();
  $('.categorizeImage').hide();
  $('#studyInstruc').hide();
  stimuliType = stimuliType.charAt(0).toUpperCase() + stimuliType.toLowerCase().slice(1);
  NextTrialStudy(0, stimuliType, itemsForStudy);
}

function NextTrialStudy(curTrial, stimuliType, itemsForStudy) {
  let curID = '#' + itemsForStudy[curTrial].id;
  $('#trialCnt').text(stimuliType + " " + (curTrial+1) + " of " + itemsForStudy.length);
  $(curID).show();
  setTimeout(function() {
    $(curID).hide();
    setTimeout(function() {
      if (curTrial < itemsForStudy.length-1) {
        NextTrialStudy(curTrial+1, stimuliType, itemsForStudy);
      } else {
        StartMemoryTestTask();
      }
    }, 1000);
  }, 3000);
}

/* MEMORY TEST TASK ------------------------------------------------- */
function StartMemoryTestTask() {
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

function StartTest(stimuliType, itemsForTest) {
  $('#testInstruc').hide();
  $('#instrucTextCur').html("Did you see this " + stimuliType + " earlier? <b>(y/n)</b>");
  $('#instrucBox').show();
  $('#experimentBox').show();
  $('.categorizeImage').hide();
  NextTrialTest(0, itemsForTest);
}

function NextTrialTest(curTrial, itemsForTest) {
  $('.categorizeImage').hide();
  $('#trialCnt').text("Trial " + (curTrial+1) + " of " + itemsForTest.length);
  $('#' + itemsForTest[curTrial].id).show();
  let startTrialTime = (new Date()).getTime();
  setTimeout(function() {
    $(document).bind('keyup', 'y', function(){PressedYesTest(curTrial, itemsForTest, startTrialTime);});
    $(document).bind('keyup', 'n', function(){PressedNoTest(curTrial, itemsForTest, startTrialTime);});
   }, 300);
}

function PressedYesTest(curTrial, itemsForTest, startTrialTime) {
  ResponseTest(itemsForTest[curTrial].isOld,
               curTrial, itemsForTest, startTrialTime);
}

function PressedNoTest(curTrial, itemsForTest, startTrialTime) {
  ResponseTest(!itemsForTest[curTrial].isOld,
               curTrial, itemsForTest, startTrialTime);
}

function ResponseTest(correct, curTrial, itemsForTest, startTrialTime) {
  let curTrialItem = itemsForTest[curTrial];
  curTrialItem['wasCorrect'] = correct;
  curTrialItem['RT'] = (new Date()).getTime() - startTrialTime;
	$(document).unbind('keyup');
  $('#' + curTrialItem.id).hide();

  setTimeout(function() {
    if (curTrial<itemsForTest.length-1) {
      NextTrialTest(curTrial+1, itemsForTest);
    } else {
      ShowDone(itemsForTest);
    }
  }, 1000);
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
                        featureFoil, valueFoil, itemsForLearning, itemsForStudy, itemsForTest) {
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
    "experimentNumber": progress['curExperiment'],
    "correctRate": correctRate,
    "earnedBonus": earnedBonus,
    "featureLearned": featureLearned,
    "featureFoil": featureFoil,
    "valueLearned": valueLearned,
    "valueFoil": valueFoil,
    "itemsForLearning": itemsForLearning,
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

  return $.post("http://web-mir.ccn.duke.edu/flower/save.php",
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
