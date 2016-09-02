using Toybox.Application;
using Toybox.WatchUi as Ui;

class ClimbRateView extends Ui.SimpleDataField {

  var saveCR=new[10]; // record 10 prior climbing rates
  var nextLoc=0; // save next altitude at saveAlt[nextLoc]
  var prevRet=0.0; // previous return value (in case we can't re-compute this time)
  var prevTime=0.0; // only use data when time changes
  var prevAlt=0.0; // prior altitude reading
  var metric=0;
  
  function initialize() {
    SimpleDataField.initialize();

// find display units
    metric=(Toybox.System.getDeviceSettings().elevationUnits==Toybox.System.UNIT_METRIC);
    label = (metric)?"Climb m/sec":"Climb ft/min";

// initialize saveCR array
    var i;
    for (i=0;i<10;i++){
     saveCR[i]=10000.0; // 10000 means uninitialized
    }
  }
  
  // compute current climbing rate
  function compute(info) {
  
    if (info==null){ // does this ever happen???
      return(prevRet);
    }
    
    if ((info.altitude==null)||(info.elapsedTime==null)){ // data not available (weird)
      return(prevRet);
    }
    
    if (info.elapsedTime == prevTime){ // don't save this sample
      return(prevRet);
    }
    
    var thisAlt=info.altitude*3.28084;     // altitude in feet
    var thisTime=info.elapsedTime/60000.0; // time in minutes
    //System.println(thisTime);
    //System.println(thisAlt);
    
    if (thisTime == prevTime){ // no time has passed
      return(prevRet); // just use old value
    }
    
    // calcuate climbing rate
    var CR=(thisAlt-prevAlt)/(thisTime-prevTime); // current climbing rate
    saveCR[nextLoc]=CR; // save in queue

    // adjust queue pointer
    ++nextLoc;
    if (nextLoc==10){
      nextLoc=0;
    } // circular queue
    
    prevAlt=thisAlt;
    prevTime=thisTime; // save for next round
    
    // now average our saved CRs
    var CRSum=0.0;
    var CRNum=0;
    var CRAvg;
    var i;
    
    for (i=0;i<10;i++){
      if (saveCR[i] != 100000.0){
        ++CRNum;
        CRSum+=saveCR[i];
      }
    } // ready to calculate average
    CRAvg=CRSum/CRNum; // should be legal
    prevRet=CRAvg;
    if (metric){
      prevRet=prevRet*.00508; // convert ft/min to meters/sec
    }
    return(prevRet);
  }
}

class ClimbRate extends Application.AppBase
{
  function initialize()
  {
    AppBase.initialize();
  }
  
  function getInitialView()
  {
    return(new ClimbRateView());
  }
}