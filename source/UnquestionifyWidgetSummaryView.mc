using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Communications as Comm;
using Toybox.System as Sys;
using Toybox.Timer as Timer;
using Toybox.Attention as Attention;

class UnquestionifyWidgetSummaryView extends Ui.View {
    hidden var mainview;
    hidden var timer;
    hidden var timerMainIdle;
    hidden var started = false;
    hidden var first = true;   
    hidden var MAX_RETRY_COUNTER=5;
    hidden var retryCounter = 0; 
    hidden var mySettings;

    function initialize(view) {
        View.initialize();
        mainview = view;
        timer = new Timer.Timer();
        timerMainIdle = new Timer.Timer();
    }

    function onShow() {
        // update UI every 3 seconds so we can refresh current notification count
        Sys.println("WidgetSummary onShow()");
        Ui.requestUpdate();
        timer.start(method(:onTimer), 1000*3, true);
    }

    function onHide() {
        Sys.println("WidgetSummaryView.onHide() called");
        timer.stop();
        retryCounter = 0;  // restart the counter 
    }

    function onTimer() {
        started = true;
        Ui.requestUpdate();
    }

    function onUpdate(dc) {
        dc.setColor(Gfx.COLOR_TRANSPARENT, Gfx.COLOR_BLACK);
        dc.clear();
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        var text = "";
        if (!started) {
            text = Ui.loadResource(Rez.Strings.AppName)+ "\nLoading...";
        } else if (mainview.initialised) {
            if (mainview.currentNotifications.size() == 0) {
                text = Ui.loadResource(Rez.Strings.AppName)+"\nNo message\nPress 'Back' to exit\n'Select' to enter";
            } else {
                text = Ui.loadResource(Rez.Strings.AppName)+"\nGot " + mainview.currentNotifications.size() + " messages\nPress 'Back' \nor 'Select'";
                // start a 2-second idle timer,  after that, go to WidgetView directly
                timerMainIdle.start(method(:onTimerMainIdle), 1000*2, false);
            }
        } else {
            // timerMainIdle.start(method(:onTimerMainIdle), 1000*2, false);  // debug
            retryCounter +=1;
            text = Ui.loadResource(Rez.Strings.AppName)+"\nPhoneApp \nUnreachable " + retryCounter;
           
            if (retryCounter>=MAX_RETRY_COUNTER){
            // don't waste time retry, stop timer ,reduce power, waiting for widget timeout
                Sys.println("retryCounter="+retryCounter + ", stop query timer to reduce power, waiting for widget timeout");
                timer.stop();
                text = Ui.loadResource(Rez.Strings.AppName)+"\nJin Stops Query\nPress 'back' to exit";
            //  exit to watchface  to do later
                // Sys.println("create intent");
                // var targetApp = new System.Intent(
                //         "manifest-id://12345678-1234-1234-1234-123412341234",
                //         {"arg"=>"CurrentAppName"}
                //         );
                // Sys.exitTo(targetApp);

            }
        }
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Gfx.FONT_LARGE, text,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        
    }
    function onTimerMainIdle(){
        if (first){     // only automatically enter WidgetView the first time after launching
            Sys.println("onTimerMainIdle, timeout, move to WidgetView");
            first = false;

            // use vibrate to inform user
            mySettings = Sys.getDeviceSettings();
            if ( mySettings has :doNotDisturb && !mySettings.doNotDisturb){
                if ( Attention has:vibrate ){
                    Sys.println("vibrate to remind user");
                     var vibeData = [
                        new Attention.VibeProfile(95, 2000), // On for two seconds
                        new Attention.VibeProfile(0, 2000),  // Off for two seconds
                        // new Attention.VibeProfile(50, 2000), // On for two seconds
                        // new Attention.VibeProfile(0, 2000),  // Off for two seconds
                        // new Attention.VibeProfile(75, 1000)  // on for one seconds
                        ];
                    Attention.vibrate(vibeData);
                }
                if (Attention has :playTone){
                    Sys.println("playTone to remind user");
                    Attention.playTone(Attention.TONE_LOUD_BEEP);
                }
            }

            Ui.pushView(mainview, new UnquestionifyInputDelegate(mainview), Ui.SLIDE_LEFT);
    
        }
     }
}

class UnquestionifySummaryInputDelegate extends Ui.BehaviorDelegate {
    var mainview;

    function initialize(view) {
        Ui.BehaviorDelegate.initialize();
        mainview = view;
    }

    function onSelect() {
        Sys.println("in WidgetSummaryView.onSelect()");
        Ui.pushView(mainview, new UnquestionifyInputDelegate(mainview), Ui.SLIDE_LEFT);
        return true;
    }

    function onBack(){
        Sys.println("WidgetSummaryView.onBack is called, return false to let its ancestor to handle");
        return false;
    }
}