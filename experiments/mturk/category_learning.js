/*
 * Setup the html fields and links to run the experiment
 */
function StartExperiment(experimentName, featureLearned, valueLearned,
                        featureFoil, valueFoil, itemsForLearning,
                        orderLearning, itemsForStudy, orderStudy,
                        itemsForTest, orderTest) {
  $('#numLearning').text(itemsForLearning.length);
  $('#numStudy').text(itemsForStudy.length);
  $('#numTest').text(itemsForTest.length);
  $('#submitButton').hide();
  $('#loading').hide();

  var stimuliType = experimentName.split("_")[0];
  document.getElementById('startLearning').onclick
    = function(){StartLearning(itemsForLearning, orderLearning);};
  document.getElementById('startStudy').onclick
    = function(){StartStudy(stimuliType, itemsForStudy, orderStudy);};
  document.getElementById('startTest').onclick
    = function(){StartTest(stimuliType, itemsForTest, orderTest);};
  document.getElementById('timSubmit').onclick
    = function(){SaveData(experimentName, featureLearned, valueLearned,
                    featureFoil, valueFoil, itemsForLearning, orderLearning,
                    itemsForStudy, orderStudy, itemsForTest, orderTest);};
  $('#startLearning').show();
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
  var avoidObjects = new Array();
  for (var i=0; i<avoidObjectsList.length; i++) {
    avoidObjects.push.apply(avoidObjects, avoidObjectsList[i]);
  }

  var obj = {};
  for (var feature in values) {
    obj[feature] = values[feature][Math.floor(Math.random()*3)];
  }

  obj[featureLearned] = valueLearned;
  obj[featureFoil] = valueFoil;

  /* Check to see if it matches anything we are supposed to avoid */
  var overlaps = false;
  for (var i=0; i<avoidObjects.length; i++) {
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
  var imageHTML = '';
  var index = 0;
  var items = [];
  var remainderItems = [];
  var pNotLearned = (1 - pLearned) / (values[featureLearned].length - 1);
  var pNotFoil = (1 - pFoil) / (values[featureFoil].length - 1);

  for (var i=0; i < values[featureLearned].length; i++) {
    for (var j=0; j < values[featureFoil].length; j++) {
      var isTarget = values[featureLearned][i] == valueLearned;
      var isFoil = values[featureFoil][j] == valueFoil;
      if (isTarget && isFoil)
        var n = pLearned * pFoil * count;
      else if (isTarget)
        var n = pLearned * pNotFoil * count;
      else if (isFoil)
        var n = pNotLearned * pFoil * count;
      else
        var n = pNotLearned * pNotFoil * count;

      for (var k=0; k<n; k++) {
        var obj = GetObject(values, featureLearned, values[featureLearned][i],
                            featureFoil, values[featureFoil][j], [...avoidObjectsList, ...items]);
        var curItem = {'object': obj,
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
    var curItem = remainderItems.splice(Math.floor(Math.random()*remainderItems.length), 1)[0];
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
  var [objects, imageHTML] = GetObjects(n, values, featureLearned, valueLearned,
                                        featureFoil, valueFoil, GetFilename, 'learn',
                                        pLearned, pFoil, []);
  $('#imagesForLearning').html(imageHTML);
  return objects;
}

/* Create the set of objects to show in the study phase */
function CreateStudyList(n, itemsForLearning, pLearned, pFoil, values, featureLearned,
                         valueLearned, featureFoil, valueFoil, GetFilename) {
  var [objects, imageHTML] = GetObjects(n, values, featureLearned, valueLearned,
                                        featureFoil, valueFoil, GetFilename, 'study',
                                        pLearned, pFoil, [...itemsForLearning]);
  $('#imagesForStudy').html(imageHTML);
  return objects;
}

/* Create the set of objects to show in the test phase */
function CreateTestList(nTest, itemsForLearning, itemsForStudy, pLearned, pFoil,
                        values, featureLearned, valueLearned, featureFoil,
                        valueFoil, GetFilename) {
  var nLures = nTest - itemsForStudy.length;
  var [objects, imageHTML] = GetObjects(nLures, values, featureLearned, valueLearned,
                                        featureFoil, valueFoil, GetFilename, 'test',
                                        pLearned, pFoil, [...itemsForLearning, ...itemsForStudy]);
  // set isOld to false
  for (var i=0; i<nLures; i++) {
    objects[i].isOld = false;
  }

  for (var i=0; i<itemsForStudy.length; i++) {
    var curItemObj = itemsForStudy[i];
    var curItem = {'object': curItemObj.object,
                   'filename': curItemObj.filename,
                   'isTarget': curItemObj.isTarget,
                   'isFoil': curItemObj.isFoil,
                   'isOld': true,
                   'id': 'test' + (i + nLures)};
    objects.push(curItem);
    imageHTML += '<img src="' + curItem.filename + '" id="' + curItem.id + '" class="categorizeImage">';
  }

  $('#imagesForTest').html(imageHTML);
  return objects;
}


/* LEARNING TASK ------------------------------------------------- */
function StartLearning(itemsForLearning, orderLearning) {
  if (IsOnTurk() && IsTurkPreview()) {
    alert('Please accept the HIT before beginning!');
    return;
  }
  $('#categoryInstruc1').hide();
  $('#instrucBox').show();
  $('#experimentBox').show();
  NextTrialLearning(0, itemsForLearning, orderLearning);
}

function NextTrialLearning(curTrial, itemsForLearning, orderLearning) {
  $('#trialCnt').text("Trial " + (curTrial+1) + " of " + itemsForLearning.length);
  $('#' + itemsForLearning[orderLearning[curTrial]].id).show();
  var startTrialTime = (new Date()).getTime();
  setTimeout(function() {
    $(document).bind('keyup', 'y', function(){PressedYesLearning(curTrial, itemsForLearning, orderLearning, startTrialTime);});
    $(document).bind('keyup', 'n', function(){PressedNoLearning(curTrial, itemsForLearning, orderLearning, startTrialTime);});
   }, 200);
}

function PressedYesLearning(curTrial, itemsForLearning, orderLearning, startTrialTime) {
  var wasCorrect =  itemsForLearning[orderLearning[curTrial]].isTarget;
  ResponseLearning(wasCorrect, curTrial, itemsForLearning, orderLearning, startTrialTime);
}

function PressedNoLearning(curTrial, itemsForLearning, orderLearning, startTrialTime) {
  var wasCorrect =  !itemsForLearning[orderLearning[curTrial]].isTarget;
  ResponseLearning(wasCorrect, curTrial, itemsForLearning, orderLearning, startTrialTime);
}

function ResponseLearning(correct, curTrial, itemsForLearning, orderLearning, startTrialTime) {
  var curTrialItem = itemsForLearning[orderLearning[curTrial]];
  $('#' + curTrialItem.id).hide();
  curTrialItem['wasCorrect'] = correct;
  curTrialItem['RT'] = (new Date()).getTime() - startTrialTime;
	$(document).unbind('keyup');

  if (correct) {
    $('#correct').show();
  } else {
    $('#wrong').show();
  }

  if (curTrial<itemsForLearning.length-1) { //XXX: For testing
    setTimeout(function() {
      $('#correct').hide();
      $('#wrong').hide();
      NextTrialLearning(curTrial+1, itemsForLearning, orderLearning);
     }, 1000);
   } else {
     setTimeout(function() {
      $('#correct').hide();
      $('#wrong').hide();
      ShowStudyStart();
     }, 1000);
   }
}

/* STUDY TASK ------------------------------------------------- */
function ShowStudyStart() {
  $('#instrucBox').hide();
  $('#experimentBox').hide();
  $('#studyInstruc').show();
  $('#instrucTextCur').html("&nbsp; &nbsp;");
}

function StartStudy(stimuliType, itemsForStudy, orderStudy) {
  $('#instrucTextCur').text("Remember these " + itemsForStudy.length + " "
                            + stimuliType.toLowerCase() + "s as best you can!");
  $('#instrucBox').show();
  $('#experimentBox').show();
  $('.categorizeImage').hide();
  $('#studyInstruc').hide();
  stimuliType = stimuliType.charAt(0).toUpperCase() + stimuliType.toLowerCase().slice(1);
  NextTrialStudy(0, stimuliType, itemsForStudy, orderStudy);
}

function NextTrialStudy(curTrial, stimuliType, itemsForStudy, orderStudy) {
  var curID = '#' + itemsForStudy[orderStudy[curTrial]].id;
  $('#trialCnt').text(stimuliType + " " + (curTrial+1) + " of " + itemsForStudy.length);
  $(curID).show();
  setTimeout(function() {
      $(curID).hide();
      if (curTrial < itemsForStudy.length-1) {
        setTimeout(function() {
          NextTrialStudy(curTrial+1, stimuliType, itemsForStudy, orderStudy);
        }, 1000);
      } else {
         setTimeout(function() {
          StartMemoryTestTask();
        }, 1000);
      }
  }, 3000);
}

/* MEMORY TEST TASK ------------------------------------------------- */
function StartMemoryTestTask() {
  $('#instrucBox').hide();
  $('#experimentBox').hide();
  $('#testInstruc').show();
  $('#instrucTextCur').html("&nbsp; &nbsp;");
}

function StartTest(stimuliType, itemsForTest, orderTest) {
  $('#testInstruc').hide();
  $('#instrucTextCur').html("Did you see this " + stimuliType + " earlier? <b>(y/n)</b>");
  $('#instrucBox').show();
  $('#experimentBox').show();
  $('.categorizeImage').hide();
  NextTrialTest(0, itemsForTest, orderTest);
}

function NextTrialTest(curTrial, itemsForTest, orderTest) {
  $('.categorizeImage').hide();
  $('#trialCnt').text("Trial " + (curTrial+1) + " of " + itemsForTest.length);
  $('#' + itemsForTest[orderTest[curTrial]].id).show();
  var startTrialTime = (new Date()).getTime();
  setTimeout(function() {
    $(document).bind('keyup', 'y', function(){PressedYesTest(curTrial, itemsForTest, orderTest, startTrialTime);});
    $(document).bind('keyup', 'n', function(){PressedNoTest(curTrial, itemsForTest, orderTest, startTrialTime);});
   }, 300);
}

function PressedYesTest(curTrial, itemsForTest, orderTest, startTrialTime) {
  var wasCorrect = itemsForTest[orderTest[curTrial]].isOld;
  ResponseTest(wasCorrect, curTrial, itemsForTest, orderTest, startTrialTime);
}

function PressedNoTest(curTrial, itemsForTest, orderTest, startTrialTime) {
  var wasCorrect = !itemsForTest[orderTest[curTrial]].isOld;
  ResponseTest(wasCorrect, curTrial, itemsForTest, orderTest, startTrialTime);
}

function ResponseTest(correct, curTrial, itemsForTest, orderTest, startTrialTime) {
  var curTrialItem = itemsForTest[orderTest[curTrial]];
  curTrialItem['wasCorrect'] = correct;
  curTrialItem['RT'] = (new Date()).getTime() - startTrialTime;
	$(document).unbind('keyup');
  $('#' + curTrialItem.id).hide();

  if (curTrial<itemsForTest.length-1) {
    setTimeout(function() {
      NextTrialTest(curTrial+1, itemsForTest, orderTest);
     }, 1000);
   } else {
     setTimeout(function() {
      ShowDone(itemsForTest);
     }, 1000);
   }
}



/* DONE ------------------------------------------------- */
function ShowDone(itemsForTest) {
  var correctCount = 0;
  for (var i=0; i<itemsForTest.length; ++i) {
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
  var numStr = window.localStorage.getItem(key);
  var num = defaultValue;
  if (numStr)
    num = parseInt(numStr, 10);
  return num;
}

function ShowNextExperiment() {
  let totalExps = GetCachedNumber('numExperiments', 1);
  let curExp = GetCachedNumber('curExperiment', 1);
  // hide the links for all experiments
  for (var i = 1; i <= totalExps; ++i) {
    $('#experiment' + i).hide();
  }

  // show the link for the current experiment
  if (curExp <= totalExps) {
    $('#experiment' + curExp).show();
  } else {
    $('#done').show();
  }

}

function PromptID(event) {
  let curID = window.localStorage.getItem('curID');
  while (!curID) {
    curID = (IsOnTurk())? GetAssignmentId() : prompt('Please enter your mTurk ID:','id');
  }
  window.localStorage.setItem('curID', curID);  // cache the ID in localStorage
}

function SaveData(experimentName, featureLearned, valueLearned, featureFoil,
                  valueFoil, itemsForLearning, orderLearning,
                  itemsForStudy, orderStudy, itemsForTest, orderTest) {
  $('#done').hide();
  $('#saving').show();

  let experimentNumber = GetCachedNumber('curExperiment', 1);
  Save("experimentNumber", experimentNumber);
  Save("featuredLearned", featureLearned);
  Save("featureFoil", featureFoil);
  Save("valueLearned", valueLearned);
  Save("valueFoil", valueFoil);

  Save("orderLearning", orderLearning);
  Save("orderStudy", orderStudy);
  Save("orderTest", orderTest);

  for (var i=0; i<itemsForLearning.length; i++) {
    Save(itemsForLearning[i].id, itemsForLearning[i]);
  }
  for (var i=0; i<itemsForStudy.length; i++) {
    Save(itemsForStudy[i].id, itemsForStudy[i]);
  }
  for (var i=0; i<itemsForTest.length; i++) {
    Save(itemsForTest[i].id, itemsForTest[i]);
  }
  Save("userAgent", navigator.userAgent);
  Save("windowWidth", $(window).width());
  Save("windowHeight", $(window).height());
  Save("screenWidth", screen.width);
  Save("screenHeight", screen.height);

  var newDate = new Date();
  var curID = window.localStorage.getItem('curID');
  if (!curID)
    curID = PromptID();

  var d = {
    "curID": curID,
    "curTime": newDate.today() + " @ " + newDate.timeNow(),
    "userAgent": navigator.userAgent,
    "windowWidth": $(window).width(),
    "windowHeight": $(window).height(),
    "screenWidth": screen.width,
    "screenHeight": screen.height,
    "comments": $('#comments').val(),
    "experimentNumber": experimentNumber,
    "featuredLearned": featureLearned,
    "featureFoil": featureFoil,
    "valueLearned": valueLearned,
    "valueFoil": valueFoil,
    "orderLearning": orderLearning,
    "orderStudy": orderStudy,
    "orderTest": orderTest,
    "itemsForLearning": itemsForLearning,
    "itemsForStudy": itemsForStudy,
    "itemsForTest": itemsForTest
  };

  SendToServer(curID, d, experimentName);
  window.localStorage.setItem('curExperiment', experimentNumber+1);
  //close();
}

function Save(name, content) {
  $('#instrucBox').append(
    "<input type='hidden' name='" + name + "' value='" + JSON.stringify(content) + "'>");
}

function SendToServer(id, curData, experimentName) {
  var dataToServer = {
    'id': id,
    'experimentName': experimentName,
    'curData': JSON.stringify(curData)
  };

  $.when($.post("http://web-mir.ccn.duke.edu/flower/save.php",
                dataToServer,
                function(data) {
                  if (IsOnTurk()) {
                    document.forms[0].submit();
                  } else {
                    $('#saving').hide();
                  }
                }
              ).fail(function(data) {
                if (IsOnTurk()) {
                  document.forms[0].submit();
                } else {
                  $('#saving').hide();
                }
              })).then(function () {close();});
}
