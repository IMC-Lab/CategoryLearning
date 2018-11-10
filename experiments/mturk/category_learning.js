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
 */
function StartExperiment(experimentName, assignmentFilename, GetFilename, values,
                         nLearning, pLearnedLearning, pFoilLearning,
                         nStudy, pLearnedStudy, pFoilStudy,
                         nTest, pLearnedTest, pFoilTest) {
  $('#numLearning').text(nLearning);
  $('#numStudy').text(nStudy);
  $('#numTest').text(nTest);
  $('#submitButton').hide();
  $('#startLearning').hide()

  // Fetch the learned category assignment from the server
  $.getJSON('http://web-mir.ccn.duke.edu/flower/' + assignmentFilename)
    .fail(function (assignment, textStatus, error) {
      console.error("getJSON failed, status: " + textStatus + ", error: " + error);
    }).done(function (assignment) {
      // Update the
      $.post('http://web-mir.ccn.duke.edu/flower/save_json.php',
             {'filename':assignmentFilename,
              'data':JSON.stringify(nextAssignment(assignment, values))})
        .fail(function (d, textStatus, error) {
          console.error("POST json failed, status: " + textStatus + ", error: " + error);
        });

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
        = function(){ StartLearning(itemsForLearning); };
      document.getElementById('startStudy').onclick
        = function(){ StartStudy(stimuliType, itemsForStudy); };
      document.getElementById('startTest').onclick
        = function(){ StartTest(stimuliType, itemsForTest); };
      document.getElementById('timSubmit').onclick
        = async function() {
            await SaveData(experimentName, featureLearned, valueLearned,
                           featureFoil, valueFoil, itemsForLearning,
                           itemsForStudy, itemsForTest);
            // try to close the window after the data is saved.
            try { close(); } catch(error) {}
          };

      // After 90s show the link to continue
      setTimeout(function () {
          $('#loadingLearning').hide();
          $('#startLearning').show();
      }, 90000);

  });
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
  }, 90000);
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
  }, 90000);
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

// A helper functino to parse numbers in localStorage
function GetCachedNumber(key, defaultValue) {
  let numStr = window.localStorage.getItem(key);
  let num = defaultValue;
  if (numStr)
    num = parseInt(numStr, 10);
  return num;
}

function ShowNextExperiment() {
  let totalExps = GetCachedNumber('numExperiments', 1);
  let curExp = GetCachedNumber('curExperiment', 1);
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

}

function GetID(event) {
  let curID = window.localStorage.getItem('curID');
  while (!curID || curID === "") {
    curID = (IsOnTurk())? GetAssignmentId() : prompt('Please enter your mTurk ID:','id');
  }
  window.localStorage.setItem('curID', curID);  // cache the ID in localStorage
  return curID;
}

function SaveData(experimentName, featureLearned, valueLearned, featureFoil,
                  valueFoil, itemsForLearning, itemsForStudy, itemsForTest) {
  $('#done').hide();
  $('#saving').show();

  let hitRate = parseFloat($('#numRight').text(), 10) / itemsForStudy.length;
  let earnedBonus = hitRate >= 0.85;
  let experimentNumber = GetCachedNumber('curExperiment', 1);

  Save("experimentNumber", experimentNumber);
  Save("hitRate", hitRate);
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
  let curID = GetID();
  let d = {
    "curID": curID,
    "curTime": newDate.today() + " @ " + newDate.timeNow(),
    "userAgent": navigator.userAgent,
    "windowWidth": $(window).width(),
    "windowHeight": $(window).height(),
    "screenWidth": screen.width,
    "screenHeight": screen.height,
    "comments": $('#comments').val(),
    "experimentNumber": experimentNumber,
    "hitRate": hitRate,
    "earnedBonus": earnedBonus,
    "featureLearned": featureLearned,
    "featureFoil": featureFoil,
    "valueLearned": valueLearned,
    "valueFoil": valueFoil,
    "itemsForLearning": itemsForLearning,
    "itemsForStudy": itemsForStudy,
    "itemsForTest": itemsForTest
  };

  window.localStorage.setItem('curExperiment', experimentNumber+1);
  return SendToServer(curID, d, experimentName);
}

function Save(name, content) {
  $('#instrucBox').append(
    "<input type='hidden' name='" + name + "' value='" + JSON.stringify(content) + "'>");
}

function SendToServer(id, curData, experimentName) {
  let dataToServer = {
    'id': id,
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
