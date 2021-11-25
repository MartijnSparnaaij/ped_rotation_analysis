% Graphical User Interface for annotating shoulders in video data

% © Martijn Sparnaaij (2019)

function varargout = shoulderGui(action, varargin)

if ~nargin
    action	= 'build';
end

if strcmpi(action, 'fcnHandle')
    varargout{:}	= eval(['@shoulderGui_' varargin{1}]);
    return
end

if nargout
    varargout		= cell(1, nargout);
    [varargout{:}]	= feval(['shoulderGui_' action], varargin{:});
else
    feval(['shoulderGui_' action], varargin{:});
end

end  % <main>
%__________________________________________________________
%% #build
%
function shoulderGui_build

figPrp = struct;
figPrp.Color            = [1 1 1] * 0.84;
figPrp.MenuBar          = 'none';
figPrp.Name             = 'Shoulder gui';
figPrp.Tag              = shoulderGui_getTag;
figPrp.NumberTitle      = 'off';
figPrp.Resize           = 'on';
figPrp.Toolbar          = 'none';
figPrp.Units            = 'points';
figPrp.Visible          = 'off';
figPrp.HandleVisibility = 'off';
figPrp.CloseRequestFcn  = @shoulderGui_close;
figPrp.ResizeFcn        = @shoulderGui_resize;
fig = figure(figPrp);

appData = struct;
appData.ctrlPnl = shoulderGui_createControlPanel(fig);
[appData.imgPnl, appData.ax] = shoulderGui_createImagePanel(fig);

appData.leftShoulderPointColor = 'r';
appData.rightShoulderPointColor = 'g';
appData.activeShoulderLineColor = [1 1 1]*0.7;
appData.inactiveShoulderLineColor = [1 1 1]*0.4;
appData.inactiveShoulderPointColor = [81, 126, 198]/255;

appData.baseMarkerSize = 4;
shoulderPointPrp                    = struct;
shoulderPointPrp.Parent             = appData.ax;
shoulderPointPrp.Marker             = 'o';
shoulderPointPrp.MarkerSize         = appData.baseMarkerSize;
shoulderPointPrp.MarkerEdgeColor    = 'k';
shoulderPointPrp.ButtonDownFcn      = @shoulderGui_shoulderPointCB;

leftShoulderPointPrp = shoulderPointPrp;
leftShoulderPointPrp.MarkerFaceColor = appData.leftShoulderPointColor;
rightShoulderPointPrp = shoulderPointPrp;
rightShoulderPointPrp.MarkerFaceColor = appData.rightShoulderPointColor;

appData.leftShoulderPointPrp = leftShoulderPointPrp;
appData.rightShoulderPointPrp = rightShoulderPointPrp;

shoulderTextPrp         = struct;
shoulderTextPrp.Parent  = appData.ax;
shoulderTextPrp.FontSize = 14;
shoulderTextPrp.Color   = [175, 143, 12]/255;
shoulderTextPrp.HorizontalAlignment = 'center';
appData.shoulderTextPrp = shoulderTextPrp;

appData.selectedMarkerSize = 8;

lnPpr               = struct;
lnPpr.Parent        = appData.ax;
lnPpr.Color         = appData.activeShoulderLineColor;
lnPpr.LineWidth     = 1;
lnPpr.PickableParts = 'none';
appData.shoulderLinePrp = lnPpr;

appData.rectanglePrps = struct;
mainPrp = struct;
mainPrp.line = struct;
mainPrp.line.width = 3;
mainPrp.line.color = 'g';

mainPrp.point = struct;
mainPrp.point.marker             = 's';
mainPrp.point.markerSize         = 10;
mainPrp.point.markerEdgeColor    = 'k';
mainPrp.point.markerFaceColor    = 'r';
mainPrp.point.markerFaceColorSelected = 'y';

appData.rectanglePrps.main = mainPrp;

subPrp = struct;
subPrp.line = struct;
subPrp.line.width = 3;
subPrp.line.colors = [0,255,161;0,255,216;0,242,255]/255;
subPrp.line.styles = {'--', ':', '-.'};

subPrp.point = struct;
subPrp.point.marker             = 's';
subPrp.point.markerSize         = 10;
subPrp.point.markerEdgeColor    = 'k';
subPrp.point.markerFaceColor    = [180,0,0]/255;
subPrp.point.markerFaceColorSelected = [255,195,0]/255;

appData.rectanglePrps.sub = subPrp;

appData = shoulderGui_init(appData);

setAppData(fig, appData)
set(fig, 'Visible', 'on')

end  % #build
%__________________________________________________________
%% #init
%
function appData = shoulderGui_init(appData)

appData.majorStepInd = 0;
appData.minorStepInd = 0;
appData.analysisStepInd = 0;
appData.analysisStepCount = 0;
appData.videoData = '';
appData.img = '';
appData.infoText = '';
appData.stepText = '';
appData.interval = 50;
appData.rectangle = '';
appData.stepInd2dataInd = [];
appData.groups = struct('name', '', 'shoulders', '');
appData.groups(1).name = 'Group 1';
appData.groups(2).name = 'Group 2';
appData.activeShoulderPoints = gobjects(0);
appData.inactiveShoulderPoints = gobjects(0);
appData.selectedPoint = [];

appData.dataFilename = '';
appData.dataFile = '';

appData.curRectangleID = 0;

appData.nextIsSecondPoint = false;
appData.lastCreatedPoint = '';

end  % #init
%__________________________________________________________
%% #createControlPanel
%
function hPnl = shoulderGui_createControlPanel(fig)

pnlPrp                  = struct;
pnlPrp.Parent           = fig;
pnlPrp.Units            = 'points';
pnlPrp.BackgroundColor  = [1 1 1] * 0.94;
pnlPrp.BorderType       = 'etchedout';
hPnl = uipanel(pnlPrp);

buttonSize = [80 25];
labelHeight = 20;

pnlData = struct;
pnlData.width = buttonSize(1)*2+3*5;

uiPrp0          = struct;
uiPrp0.Parent   = hPnl;
uiPrp0.Units    = 'points';
uiPrp0.FontSize = 11;

x = 5;
y = 5;

uiPrp                       = uiPrp0;
uiPrp.Style                 = 'pushbutton';
uiPrp.String                = 'Stop';
uiPrp.HorizontalAlignment   = 'left';
uiPrp.Callback              = '';
uiPrp.Position              = [x y buttonSize];
uiPrp.Callback              = @shoulderGui_stop;
pnlData.stopButton          = uicontrol(uiPrp);

uiPrp                       = uiPrp0;
uiPrp.Style                 = 'pushbutton';
uiPrp.String                = 'Go to step';
uiPrp.HorizontalAlignment   = 'left';
uiPrp.Callback              = '';
uiPrp.Enable                = 'off';
uiPrp.Position              = [x+5+buttonSize(1) y buttonSize];
uiPrp.Callback              = @shoulderGui_goTo;
pnlData.goToButton          = uicontrol(uiPrp);
y = y + buttonSize(2) + 15;

uiPrp                       = uiPrp0;
uiPrp.Style                 = 'pushbutton';
uiPrp.String                = 'Previous';
uiPrp.Enable                = 'off';
uiPrp.HorizontalAlignment   = 'left';
uiPrp.Callback              = @shoulderGui_previousStep;
uiPrp.Position              = [x y buttonSize];
pnlData.prevButton          = uicontrol(uiPrp);

uiPrp                       = uiPrp0;
uiPrp.Style                 = 'pushbutton';
uiPrp.String                = 'Start';
uiPrp.HorizontalAlignment   = 'left';
uiPrp.Callback              = @shoulderGui_nextStep;
uiPrp.Position              = [x+5+buttonSize(1) y buttonSize];
pnlData.nextButton          = uicontrol(uiPrp);
y = y + buttonSize(2) + 20;


uiPrp                       = uiPrp0;
uiPrp.Style                 = 'text';
uiPrp.HorizontalAlignment   = 'left';
uiPrp.ForegroundColor       = [1 1 1]*0.3;
uiPrp.BackgroundColor       = get(hPnl, 'BackgroundColor');

pnlData.groupBaseStr = 'Shoulders of';
pnlData.firstGroupName = 'shoulderFirstGroup';
pnlData.secondGroupName = 'shoulderSecondGroup';


stepsC = {
    %name                     label                       isSubstep
    'loadData'               'Load video'                false
    'setDensRectangle'        'Set density rectangle'     false
    'setInterval'             'Set interval'              false
    'setGroupNames'           'Set group names'           false
    'performAnalysis'         'Perform analysis'          false
    pnlData.firstGroupName    'Shoulders of group ...'    true
    pnlData.secondGroupName   'Shoulders of group ...'    true
    };

steps = cell2struct(stepsC, {'name', 'label', 'isSubstep'}, 2);
stepInd2name = cell(sum(cell2mat(stepsC(:,3)) == false),2);
majorInd = 0;
minorInd = 0;

yTop = y + (numel(steps) - 1)*(labelHeight + 5);
yLoc = yTop;

for ii = 1:numel(steps)
    if steps(ii).isSubstep
        label = sprintf('   * %s', steps(ii).label);
        fontAngle = 'italic';
    else
        label = sprintf('- %s', steps(ii).label);
        fontAngle = 'normal';
    end
    uiPrp.FontAngle             = fontAngle;
    uiPrp.String                = label;
    uiPrp.Position              = [x yLoc pnlData.width - 10 labelHeight];
    pnlData.(steps(ii).name)    = uicontrol(uiPrp);
    yLoc = yLoc - (labelHeight + 5);
    if steps(ii).isSubstep
        minorInd = minorInd + 1;
        stepInd2name{majorInd,2}{end+1} = steps(ii).name;
    else
        majorInd = majorInd + 1;
        minorInd = 0;
        stepInd2name(majorInd,:) = {steps(ii).name, {}};
    end
end % for ii

y = yTop + labelHeight + 5;

uiPrp.ForegroundColor       = 'k';
uiPrp.FontSize              = 14;
uiPrp.FontWeight            = 'bold';
uiPrp.String                = 'Steps:';
uiPrp.Position              = [x y pnlData.width - 10 labelHeight];
uicontrol(uiPrp)

pnlData.stepInd2name = stepInd2name;
pnlData.height = y + labelHeight + 5;

pnlData.steps = steps;
setAppData(hPnl, pnlData)

end  % #createControlPanel
%__________________________________________________________
%% #createImagePanel
%
function [hPnl, ax] = shoulderGui_createImagePanel(fig)

pnlPrp                  = struct;
pnlPrp.Parent           = fig;
pnlPrp.Units            = 'points';
pnlPrp.BackgroundColor  = [1 1 1] * 0.94;
pnlPrp.BorderType       = 'etchedout';
hPnl = uipanel(pnlPrp);

axPrp           = struct;
axPrp.Parent    = hPnl;
axPrp.FontSize  = 10;
axPrp.Box       = 'on';
ax = axes(axPrp);

xlabel(ax, 'X')
ylabel(ax, 'Y')

pnlData.overlay = '';

setAppData(hPnl, pnlData)

end  % #createImagePanel
%__________________________________________________________
%% #getTag
%
function tag = shoulderGui_getTag

tag = 'shoulderGui';

end  % #getTag
%__________________________________________________________
%% #close
%
function shoulderGui_close(h, evd)

fig = hfigure(h);

title = 'Close?';
question = 'Do you want to close the Shoulder gui window?';

answer = questdlg(question, title, 'Yes', 'No', 'No');
if strcmpi(answer, 'yes')
    appData = getAppData(fig);
    if ~isempty(appData.dataFilename)
        shoulderGui_saveData2file(appData, 'all')
    end
    delete(fig)
end

end  % #close
%__________________________________________________________
%% #resize
%
function shoulderGui_resize(h, evd)

fig = hfigure(h);
appData = getAppData(fig);
if strcmpi(get(fig, 'Visible'), 'off')
    return
end

% =========== get data ===========
figPos = get(fig, 'Position');

% =========== control panel ===========
ctrlPnlData = getAppData(appData.ctrlPnl);
ctrlPnlPos = [0, figPos(4) - ctrlPnlData.height, ctrlPnlData.width, ctrlPnlData.height];

% =========== image panel ===========

imgPnlPos = [ctrlPnlPos(1) + ctrlPnlPos(3), 0,...
    figPos(3) - ctrlPnlPos(1)  - ctrlPnlPos(3), figPos(4)];

imgPnlData = getAppData(appData.imgPnl);
if ~isempty(imgPnlData.overlay)
    overlayPos = get(imgPnlData.overlay, 'pos');
    x = max(0, (imgPnlPos(3) - overlayPos(3))/2);
    y = max(0, (imgPnlPos(4) - overlayPos(4))/2);
    overlayPos(1:2) = [x, y];
    set(imgPnlData.overlay, 'Position', overlayPos);
end

% =========== set data ===========
set(appData.ctrlPnl, 'Position', ctrlPnlPos);
set(appData.imgPnl, 'Position', imgPnlPos);

end  % #resize
%__________________________________________________________
%% #nextStep
%
function shoulderGui_nextStep(h, evd)

fig = hfigure(h);
appData = getAppData(fig);

switch appData.majorStepInd
    case 0 % Start
        appData.majorStepInd = appData.majorStepInd + 1;
    case 1 % Load video
        succes = shoulderGui_videoLoaded(fig);
        if succes
            appData = shoulderGui_initSaveFile(appData);
            shoulderGui_saveData2file(appData, 'videoData');
            appData.majorStepInd = appData.majorStepInd + 1;
            set(appData.img, 'ButtonDownFcn', @shoulderGui_rectangleButtonDownCB)
        end
    case 2 % Set density rectangle
        if isempty(appData.rectangle)
            msgbox('Rectangle not yet defined!', 'Cannot continue')
            return
        end
        shoulderGui_saveData2file(appData, 'rectangle');
        shoulderGui_rectangleCornersSwitch(appData, false)
        appData.majorStepInd = appData.majorStepInd + 1;
    case 3 % Set interval
        [ok, interval] = shoulderGui_getInterval(appData);
        if ~ok
            return
        end
        appData.majorStepInd = appData.majorStepInd + 1;
        if interval ~= appData.interval || isempty(appData.stepInd2dataInd)
            appData.interval = interval;
            appData = shoulderGui_calcIntervalCount(appData);
            appData = shoulderGui_setAxTitle(appData, 1);
            shoulderGui_saveData2file(appData, 'interval');
        else
            appData = shoulderGui_setAxTitle(appData, 1);
        end
    case 4 % Set group names
        [ok, appData] = shoulderGui_checkGroupNames(appData);
        if ok
            appData.majorStepInd = appData.majorStepInd + 1;
            appData.analysisStepInd = 1;
            appData.minorStepInd = 1;
            shoulderGui_updateGroupNamesInCtrlPnl(fig, appData.groups)
            if isempty(appData.dataFilename)
                appData.dataFilename = shoulderGui_chooseSaveFilename();
            end
            shoulderGui_saveData2file(appData, 'groups');
            set(appData.img, 'ButtonDownFcn', @shoulderGui_addShoulderPoint)
            appData = shoulderGui_setPointsBasedOnData(appData);
            set(getAppData(appData.ctrlPnl, 'goToButton'), 'enable', 'on')
        end
    case 5 % perform analysis
        appData = shoulderGui_saveShoulderData(appData, appData.minorStepInd, appData.analysisStepInd);
        if appData.minorStepInd == 1
            appData.minorStepInd = 2;
        else
            appData.minorStepInd = 1;
            appData.analysisStepInd = appData.analysisStepInd + 1;
            if appData.analysisStepInd > appData.analysisStepCount
                shoulderGui_stop(fig, '')
                return
            end
            shoulderGui_saveData2file(appData, 'groups');
            % Show next frame
            appData = shoulderGui_setAxImage(appData, appData.analysisStepInd);
            % Update step text
            % set active and inactive points based on data
            appData = shoulderGui_setPointsBasedOnData(appData);
        end
end % switch

setAppData(fig, appData)
shoulderGui_updateImagePanel(fig)
shoulderGui_updateSteps(fig)

end  % #nextStep
%__________________________________________________________
%% #previousStep
%
function shoulderGui_previousStep(h, evd)

fig = hfigure(h);

appData = getAppData(fig);
if appData.majorStepInd == 2
    % Remove rectange
    while ~isempty(getAppData(fig, 'rectangle'))
        shoulderGui_clearRectangle(fig);
    end % while
    appData = getAppData(fig);
end

if appData.majorStepInd == 3
    shoulderGui_rectangleCornersSwitch(appData, true)
    set(fig, 'WindowKeyPressFcn', @shoulderGui_rectangleKeyPressAddSub)
end

if appData.majorStepInd == 4
    shoulderGui_saveData2file(appData, 'groups');
end

if appData.majorStepInd == 5
    appData = shoulderGui_saveShoulderData(appData, appData.minorStepInd, appData.analysisStepInd);
    if appData.minorStepInd == 1
        appData.analysisStepInd = appData.analysisStepInd - 1;
        appData = shoulderGui_clearPoints(appData);
        if appData.analysisStepInd == 0
            appData.minorStepInd = 0;
            appData.majorStepInd = appData.majorStepInd - 1;
            set(getAppData(appData.ctrlPnl, 'goToButton'), 'enable', 'off')
            set(appData.img, 'ButtonDownFcn', '')
        else
            appData.minorStepInd = 2;
            % Set previous frame
            appData = shoulderGui_setAxImage(appData, appData.analysisStepInd);
            % Add points of current step and set group 2 to active
            appData = shoulderGui_setPointsBasedOnData(appData);
        end
    elseif appData.minorStepInd == 2
        appData.minorStepInd = 1;
        % Add points of current step
        appData = shoulderGui_setPointsBasedOnData(appData);
    end
else
    appData.majorStepInd = appData.majorStepInd - 1;
end

setAppData(fig, appData)
shoulderGui_updateImagePanel(fig)
shoulderGui_updateSteps(fig)

end  % #previousStep
%__________________________________________________________
%% #stop
%
function shoulderGui_stop(h, evd)

answer = questdlg('Are you sure the analysis is finished', 'Stop', 'Yes', 'No', 'No');
if ~strcmpi(answer, 'yes')
    return
end

fig = hfigure(h);
appData = getAppData(fig);
shoulderGui_saveData2file(appData, 'all')
appData = shoulderGui_init(appData);
cla(appData.ax)
delete(appData.axTitle)
appData.axTitle = '';
setAppData(fig, appData)

set(getAppData(appData.ctrlPnl, 'goToButton'), 'enable', 'off')

shoulderGui_updateImagePanel(fig)
shoulderGui_updateSteps(fig)

end  % #stop
%__________________________________________________________
%% #goTo
%
function shoulderGui_goTo(h, evd)

fig = hfigure(h);
analysisStepCount = getAppData(fig, 'analysisStepCount');
curStepInd = getAppData(fig, 'analysisStepInd');
answer = inputdlg({'Go to step:'},'Go to step', [1, 20], {num2str(curStepInd)});

if isempty(answer)
    return
end

newStepInd = str2num(answer{1}); %#ok<ST2NM>
if numel(newStepInd) ~= 1
    hDlg = errordlg('The value must be numeric', 'Invalid value');
    waitfor(hDlg)
    shoulderGui_goTo(fig, {})
    return
end

if floor(newStepInd) ~= newStepInd
    hDlg = errordlg('The value must be an integer', 'Invalid value');
    waitfor(hDlg)
    shoulderGui_goTo(fig, {})
    return
end
if newStepInd <= 0 || newStepInd > analysisStepCount
    hDlg = errordlg(sprintf('The value must be larger than 0 and smaller than %u', analysisStepCount), 'Invalid value');
    waitfor(hDlg)
    shoulderGui_goTo(fig, {})
    return
end

if newStepInd == curStepInd
    return
end

appData = getAppData(fig);
if appData.minorStepInd == 1
    appData = shoulderGui_saveShoulderData(appData, appData.minorStepInd, appData.analysisStepInd);
end

appData.minorStepInd = 2;
appData = shoulderGui_saveShoulderData(appData, appData.minorStepInd, appData.analysisStepInd);

shoulderGui_saveData2file(appData, 'groups');

appData.analysisStepInd = newStepInd;
appData.minorStepInd = 1;

appData = shoulderGui_setAxImage(appData, appData.analysisStepInd);
appData = shoulderGui_setPointsBasedOnData(appData);

setAppData(fig, appData)

shoulderGui_updateImagePanel(fig)
shoulderGui_updateSteps(fig)

end  % #goTo
%__________________________________________________________
%% #updateSteps
%
function shoulderGui_updateSteps(fig)

majorStepInd = getAppData(fig, 'majorStepInd');
minorStepInd = getAppData(fig, 'minorStepInd');
pnlData = getAppData(getAppData(fig, 'ctrlPnl'));

for ii = 1:numel(pnlData.steps)
    set(pnlData.(pnlData.steps(ii).name), 'FontWeight', 'normal')
end % for ii

set(pnlData.nextButton, 'String', 'Next')
set(pnlData.prevButton, 'enable', 'on')
if majorStepInd <= 1
    set(pnlData.prevButton, 'enable', 'off')
end
if majorStepInd == 0
    set(pnlData.nextButton, 'String', 'Start')
    return
end

mainUiCtrl = pnlData.(pnlData.stepInd2name{majorStepInd,1});
set(mainUiCtrl, 'FontWeight', 'bold')

if minorStepInd > 0
    minorUiCtrl = pnlData.(pnlData.stepInd2name{majorStepInd,2}{minorStepInd});
    set(minorUiCtrl, 'FontWeight', 'bold')
end

end  % #updateSteps
%__________________________________________________________
%% #updateImagePanel
%
function shoulderGui_updateImagePanel(fig)

appData = getAppData(fig);

pnlData = getAppData(appData.imgPnl);

% Remove all current ui controls
if ~isempty(pnlData.overlay)
    delete(pnlData.overlay)
    pnlData.overlay = '';
end

% Remove callbacks
pnlPrp                  = struct;
pnlPrp.Parent           = appData.imgPnl;
pnlPrp.Units            = 'points';
pnlPrp.BackgroundColor  = [1 1 1] * 0.40;
pnlPrp.BorderType       = 'beveledout';

switch appData.majorStepInd
    case 1 % Load video
        pnlPrp.Position = [0,0,100,45];
        pnlData.overlay = uipanel(pnlPrp);
        uiPrp           = struct;
        uiPrp.Parent    = pnlData.overlay;
        uiPrp.Units     = 'Points';
        uiPrp.Style     = 'PushButton';
        uiPrp.String    = 'Load video';
        uiPrp.FontSize  = 11;
        uiPrp.Position  = [9, 9, 85, 25];
        uiPrp.Callback  = @shoulderGui_loadData;
        uicontrol(uiPrp)
    case 3 % Set interval
        pnlData.interval = getAppData(fig, 'interval');
        pnlPrp.Position = [0,0,140,40];
        pnlData.overlay = uipanel(pnlPrp);
        uiPrp                   = struct;
        uiPrp.Parent            = pnlData.overlay;
        uiPrp.Units             = 'Points';
        uiPrp.BackgroundColor   = get(pnlData.overlay, 'BackgroundColor');
        uiPrp.ForegroundColor   = 'w';
        uiPrp.Style             = 'text';
        uiPrp.String            = 'Interval [frames]:';
        uiPrp.FontSize          = 11;
        uiPrp.FontWeight        = 'bold';
        uiPrp.Position          = [9, 6, 95, 20];
        uicontrol(uiPrp)
        
        uiPrp.Style             = 'edit';
        uiPrp.BackgroundColor   = 'w';
        uiPrp.ForegroundColor   = 'k';
        uiPrp.String            = num2str(appData.interval);
        uiPrp.FontWeight        = 'normal';
        uiPrp.Position          = [104, 9, 30, 20];
        pnlData.intervalEdit    = uicontrol(uiPrp);
    case 4
        pnlPrp.Position = [0,0,140,67];
        pnlData.overlay = uipanel(pnlPrp);
        
        uiPrp                   = struct;
        uiPrp.Parent            = pnlData.overlay;
        uiPrp.Units             = 'Points';
        uiPrp.BackgroundColor   = get(pnlData.overlay, 'BackgroundColor');
        uiPrp.ForegroundColor   = 'w';
        uiPrp.Style             = 'text';
        uiPrp.FontSize          = 11;
        uiPrp.FontWeight        = 'bold';
        
        uiPrp.String            = 'Group 2:';
        uiPrp.Position          = [9, 6, 50, 20];
        uicontrol(uiPrp)
        uiPrp.String            = 'Group 1:';
        uiPrp.Position          = [9, 33, 50, 20];
        uicontrol(uiPrp)
        
        uiPrp.Style             = 'edit';
        uiPrp.BackgroundColor   = 'w';
        uiPrp.ForegroundColor   = 'k';
        uiPrp.FontWeight        = 'normal';
        
        uiPrp.String            = appData.groups(2).name;
        uiPrp.Position          = [59, 9, 75, 20];
        pnlData.group2Edit      = uicontrol(uiPrp);
        uiPrp.String            = appData.groups(1).name;
        uiPrp.Position          = [59, 36 75, 20];
        pnlData.group1Edit      = uicontrol(uiPrp);
end

setAppData(appData.imgPnl, pnlData)
shoulderGui_resize(fig, '')

end  % #updateImagePanel
%__________________________________________________________
%% #loadData
%
function shoulderGui_loadData(h, evd)

main = fileparts(cd);
dataPd = fullfile(main, 'Data');
if ~isfolder(dataPd)
    dataPd = cd;
end

[file, path, ind] = uigetfile({'*.mp4';'*.mat'}, 'Select movie', dataPd);
if file == 0
    return
end

if ind == 2
    shoulderGui_loadMat(path, file, hfigure(h))
else
    videoData = shoulderGui_loadVideo(path, file);
    fig = hfigure(h);
    setAppData(fig, videoData, 'videoData')
    shoulderGui_initAxImage(fig)
end

end  % #loadData
%__________________________________________________________
%% #loadVideo
%
function videoData = shoulderGui_loadVideo(path, file)

videoData = struct;
videoData.flNm = fullfile(path, file);
videoData.file = file;

try
    videoData.vidObj = VideoReader(videoData.flNm);
catch
    errordlg('Error while loading video', 'Error')
    return
end

end  % #loadVideo
%__________________________________________________________
%% #loadMat
%
function shoulderGui_loadMat(path, file, fig)

filename = fullfile(path, file);
data = load(filename);

appData = getAppData(fig);


if isfile(data.video.filename)
    [pd, fl, ext] = fileparts(data.video.filename);
else
    [~, fl, ext] = fileparts(data.video.filename);
    pd = path;
end
videoData = shoulderGui_loadVideo(pd, [fl, ext]);
appData.videoData = videoData;
appData.interval = data.interval;

setAppData(fig, appData)
shoulderGui_initAxImage(fig)
appData = getAppData(fig);
appData.analysisStepCount = data.analysisStepCount;
appData.stepInd2dataInd = 1:data.analysisStepCount;
setAppData(fig, appData)

setAppData(fig, 1, 'curRectangleID')
shoulderGui_addRectangleFromData(fig, data.rectangle.main)
for ii = 1:numel(data.rectangle.subs)
    setAppData(fig, 1 + ii, 'curRectangleID')
    shoulderGui_addRectangleFromData(fig, data.rectangle.subs(ii))
end % for ii

appData = getAppData(fig);
shoulderGui_rectangleCornersSwitch(appData, false)

for ii = 1:numel(data.groups)
    appData.groups(ii) = data.groups(ii);
    for jj = 1:size(appData.groups(ii).shoulders, 1)
        orgPoints = appData.groups(ii).shoulders{jj,3};
        if isempty(orgPoints) || size(orgPoints, 2) == 5
            continue
        end
        pointData = nan(size(orgPoints,1),5);
        pointData(:,1:4) = orgPoints;
        appData.groups(ii).shoulders{jj,3} = pointData;
    end % for jj
end % for ii
appData = shoulderGui_checkShoulders(appData);

appData.majorStepInd = 4;
appData = shoulderGui_setAxImage(appData, 1);
appData.dataFilename = filename;
appData = shoulderGui_initSaveFile(appData);
setAppData(fig, appData)

shoulderGui_updateImagePanel(fig)
shoulderGui_nextStep(fig, {})

end  % #loadMat
%__________________________________________________________
%% #videoLoaded
%
function succes = shoulderGui_videoLoaded(fig)

succes = ~isempty(getAppData(fig, 'videoData'));

end  % #videoLoaded
%__________________________________________________________
%% #getInterval
%
function [ok, interval] = shoulderGui_getInterval(appData)

h = getAppData(appData.imgPnl, 'intervalEdit');
interval = str2num(get(h, 'String')); %#ok<ST2NM>
ok = false;
if numel(interval) ~= 1
    errordlg('The value must be numeric', 'Invalid value')
    set(h, 'String', num2str(appData.interval))
    return
end

if floor(interval) ~= interval
    errordlg('The value must be an integer', 'Invalid value')
    set(h, 'String', num2str(appData.interval))
    return
end
if interval <= 0
    errordlg('The value must be larger than 0', 'Invalid value')
    set(h, 'String', num2str(appData.interval))
    return
end

ok = true;

end  % #getInterval
%__________________________________________________________
%% #initAxImage
%
function shoulderGui_initAxImage(fig)

imgPnl = getAppData(fig, 'imgPnl');
ax = getAppData(fig, 'ax');

txtPrp                      = struct;
txtPrp.Parent               = ax;
txtPrp.Color                = 'w';
txtPrp.FontSize             = 11;
txtPrp.HorizontalAlignment  = 'right';
txtPrp.VerticalAlignment    = 'top';
txtPrp.Units                = 'normalized';
txtPrp.Position             = [1,1,0];

setAppData(imgPnl, txtPrp, 'infoTextPrp');

appData = getAppData(fig);
appData = shoulderGui_setAxImage(appData, 1);
xlabel(appData.ax, 'X')
ylabel(appData.ax, 'Y')
appData.axTitle = title(appData.ax, 'Step # of #');
setAppData(fig, appData)

end  % #initAxImage
%__________________________________________________________
%% #setAxImage
%
function appData = shoulderGui_setAxImage(appData, stepInd)

pnlData = getAppData(appData.imgPnl);
videoData = appData.videoData;
ax = appData.ax;

frameNr = (stepInd - 1)*appData.interval + 1;
time = (frameNr - 1)*(1/videoData.vidObj.FrameRate);

videoData.vidObj.CurrentTime = time;
frame = readFrame(videoData.vidObj);

if isempty(appData.img)
    appData.img = imagesc(ax, frame);
else
    set(appData.img, 'CData', frame)
end

if ~isempty(appData.rectangle)
    uistack(appData.rectangle.ll2ul, 'top')
    uistack(appData.rectangle.ll2lr, 'top')
    uistack(appData.rectangle.lr2ur, 'top')
    uistack(appData.rectangle.ul2ur, 'top')
    for ii = 1:numel(appData.rectangle.subs)
        uistack(appData.rectangle.subs(ii).ll2ul, 'top')
        uistack(appData.rectangle.subs(ii).ll2lr, 'top')
        uistack(appData.rectangle.subs(ii).lr2ur, 'top')
        uistack(appData.rectangle.subs(ii).ul2ur, 'top')
    end % for ii
end

min = floor(time/60);
sec = floor(time - min*60);
milisec = round((time - min*60 - sec)*1000);

infoStr = sprintf('Time: %02u:%02u:%04u, Frame: %03u, Frame rate: %f [frame/s]',...
    min, sec, milisec, frameNr, videoData.vidObj.FrameRate);

if ~isempty(appData.infoText)
    set(appData.infoText, 'String', infoStr)
else
    txtPrp = pnlData.infoTextPrp;
    txtPrp.String = infoStr;
    appData.infoText = text(txtPrp);
end

appData = shoulderGui_setAxTitle(appData, stepInd);
set(ax, 'DataAspectRatioMode', 'manual', 'DataAspectRatio', [1, 1 1]);

end  % #setAxImage
%__________________________________________________________
%% #setAxTitle
%
function appData = shoulderGui_setAxTitle(appData, stepInd)

if appData.analysisStepCount > 0
    set(appData.axTitle, 'String', sprintf('Step %u of %u', stepInd, appData.analysisStepCount))
end

end  % #setAxTitle
%__________________________________________________________
%% #calcIntervalCount
%
function appData = shoulderGui_calcIntervalCount(appData)

frameCount = appData.videoData.vidObj.Duration*appData.videoData.vidObj.FrameRate;
appData.analysisStepCount = floor(frameCount/appData.interval);

if ~isempty(appData.groups(1).shoulders)
    for ii = 1:numel(appData.groups)
        orgShoulderData = appData.groups(ii).shoulders;
        orgShoulderData(cellfun(@isempty, orgShoulderData(:,1)),1) = {NaN};
        orgFrameNrs = cell2mat(orgShoulderData(:,1));
        newFrameNrs = [1:appData.interval:appData.interval*appData.analysisStepCount]';
        frameNrs = union(newFrameNrs, orgFrameNrs);
        [~, orgDataInd ,~] = intersect(frameNrs, orgFrameNrs);
        [~, newDataInd ,~] = intersect(frameNrs, newFrameNrs);
        appData.groups(ii).shoulders = cell(numel(frameNrs), 3);
        for jj = 1:numel(orgDataInd)
            appData.groups(ii).shoulders(orgDataInd(jj),:) = orgShoulderData(jj,:);
        end % for jj
        appData.stepInd2dataInd = newDataInd;
    end % for ii
else
    appData.stepInd2dataInd = 1:appData.analysisStepCount;
    for ii = 1:numel(appData.groups)
        appData.groups(ii).shoulders = cell(appData.analysisStepCount, 3);
    end % for ii
end

end  % #calcIntervalCount
%__________________________________________________________
%% #rectangleButtonDownCB
%
function shoulderGui_rectangleButtonDownCB(h, evd)

fig = hfigure(h);

curID = getAppData(fig, 'curRectangleID');
if curID == 0
    label = 'Main';
    rectangle = struct;
    rectangle.activePoint = '';
    rectangle.subs = struct([]);
    setAppData(fig, rectangle, 'rectangle');
else
    label = char(curID + 64);
end

setAppData(fig, curID+1, 'curRectangleID');

% draw rectangle
shoulderGui_drawRectangle(fig, evd.IntersectionPoint(1),...
    evd.IntersectionPoint(2), evd.IntersectionPoint(1),...
    evd.IntersectionPoint(2), 0, label);

appData = getAppData(fig);
rectangleS = shoulderGui_getActiveRectangle(fig);
set(rectangleS.ur, 'MarkerFaceColor',...
    shoulderGui_getDrawPrp(appData, 'pointMarkerFaceColorSelected'));

appData.rectangle.activePoint = rectangleS.ur;

setAppData(fig, appData)
% Add windowButtonMotionFcn
% Add windowButtonUpFcn
% Remove windowButtonDownFcn
set(appData.img, 'ButtonDownFcn', '')

set(fig, 'WindowButtonMotionFcn', {@shoulderGui_rectangleButtonMotionCB, fig})
set(fig, 'WindowButtonUpFcn', {@shoulderGui_rectangleButtonUpCB, fig})
drawnow

end  % #rectangleCB
%__________________________________________________________
%% #rectangleButtonMotionCB
%
function shoulderGui_rectangleButtonMotionCB(h, evd, fig)

% update regtangle
activePoint = getAppData(fig, 'rectangle.activePoint');

set(activePoint, 'XData', evd.IntersectionPoint(1),...
    'YData', evd.IntersectionPoint(2))
rectangleS = shoulderGui_getActiveRectangle(fig);

if activePoint == rectangleS.ur
    x0 = get(rectangleS.ll, 'XData');
    y0 = get(rectangleS.ll, 'YData');
    x1 = evd.IntersectionPoint(1);
    y1 = evd.IntersectionPoint(2);
else
    x1 = get(rectangleS.ur, 'XData');
    y1 = get(rectangleS.ur, 'YData');
    x0 = evd.IntersectionPoint(1);
    y0 = evd.IntersectionPoint(2);
end

if rectangleS.angle ~= 0
    angle = -rectangleS.angle;
    R = [cosd(angle), -sind(angle);sind(angle), cosd(angle)];
    virtualCoords = R*[x1-x0; y1-y0];
    x1 = virtualCoords(1) + x0;
    y1 = virtualCoords(2) + y0;
end

lineCoords = shoulderGui_getRectangleLineCoords(x0, y0, x1, y1, rectangleS.angle);
set(rectangleS.ll2ul, 'XData', lineCoords.ll2ul.x, 'YData', lineCoords.ll2ul.y)
set(rectangleS.ll2lr, 'XData', lineCoords.ll2lr.x, 'YData', lineCoords.ll2lr.y)
set(rectangleS.lr2ur, 'XData', lineCoords.lr2ur.x, 'YData', lineCoords.lr2ur.y)
set(rectangleS.ul2ur, 'XData', lineCoords.ul2ur.x, 'YData', lineCoords.ul2ur.y)
set(rectangleS.hLabel, 'Position', [mean(lineCoords.ul2ur.x), mean(lineCoords.ul2ur.y), 0])

drawnow

end  % #rectangleButtonMotionCB
%__________________________________________________________
%% #rectangleButtonUpCB
%
function shoulderGui_rectangleButtonUpCB(h, evd, fig)

set(fig, 'WindowButtonMotionFcn', '')
set(fig, 'WindowButtonUpFcn', '')

try
    appData = getAppData(fig);
    set(appData.rectangle.activePoint, 'MarkerFaceColor', ...
        shoulderGui_getDrawPrp(appData, 'pointMarkerFaceColor'))
    appData.rectangle.activePoint = '';
    
    setAppData(fig, appData)
    
    rectangleS = shoulderGui_getActiveRectangle(fig);
    set(rectangleS.ll, 'ButtonDownFcn', @shoulderGui_rectangleCornerCB)
    set(rectangleS.ur, 'ButtonDownFcn', @shoulderGui_rectangleCornerCB)
    set(fig, 'WindowKeyPressFcn', @shoulderGui_rectangleKeyPressAddSub)
catch
end

end  % #rectangleButtonUpCB
%__________________________________________________________
%% #rectangleCornerCB
%
function shoulderGui_rectangleCornerCB(h, evd)

fig = hfigure(h);
shoulderGui_setActiveRectangle(fig, h)
if evd.Button == 3
    shoulderGui_changeAngle(fig)
    return
end

appData = getAppData(fig);
appData.rectangle.activePoint = h;
setAppData(fig, appData)

set(appData.rectangle.activePoint, 'MarkerFaceColor', ...
    shoulderGui_getDrawPrp(appData, 'pointMarkerFaceColorSelected'))

rectangleS = shoulderGui_getActiveRectangle(fig);
set(rectangleS.ll, 'ButtonDownFcn', '')
set(rectangleS.ur, 'ButtonDownFcn', '')

set(fig, 'WindowButtonMotionFcn', {@shoulderGui_rectangleButtonMotionCB, fig})
set(fig, 'WindowButtonUpFcn', {@shoulderGui_rectangleButtonUpCB, fig})
set(fig, 'WindowKeyPressFcn', @shoulderGui_rectangleKeyPressButtonDown)
drawnow

end  % #rectangleCornerCB
%__________________________________________________________
%% #rectangleKeyPressButtonDown
%
function shoulderGui_rectangleKeyPressButtonDown(h, evd)

if ~strcmpi(evd.Key, 'delete')
    return
end

fig = hfigure(h);

shoulderGui_clearRectangle(fig);

appData = getAppData(fig);
if appData.curRectangleID == 1
    set(appData.rectangle.ll, 'ButtonDownFcn', @shoulderGui_rectangleCornerCB)
    set(appData.rectangle.ur, 'ButtonDownFcn', @shoulderGui_rectangleCornerCB)
else
    set(appData.img, 'ButtonDownFcn', @shoulderGui_rectangleButtonDownCB)
end

set(fig, 'WindowButtonMotionFcn', '')
set(fig, 'WindowButtonUpFcn', '')
set(fig, 'WindowKeyPressFcn', '')

end  % #rectangleKeyPressButtonDown
%__________________________________________________________
%% #rectangleKeyPressAddSub
%
function shoulderGui_rectangleKeyPressAddSub(h, evd)

if ~(strcmpi(evd.Key, 'a') && any(strcmpi(evd.Modifier, 'shift')))
    return
end

fig = hfigure(h);
appData = getAppData(fig);

set(appData.rectangle.ll, 'ButtonDownFcn', '')
set(appData.rectangle.ur, 'ButtonDownFcn', '')

set(appData.img, 'ButtonDownFcn', @shoulderGui_rectangleButtonDownCB)

end  % #rectangleKeyPressAddSub
%__________________________________________________________
%% #changeAngle
%
function shoulderGui_changeAngle(fig)

rectangleS = shoulderGui_getActiveRectangle(fig);
curAngle = rectangleS.angle;
answer = inputdlg({'Rectangle angle [degrees]:'},'Rectangle angle', [1, 35], {num2str(curAngle)});
if isempty(answer)
    return
end

newAngle = str2num(answer{1}); %#ok<ST2NM>
if numel(newAngle) ~= 1
    hDlg = errordlg('The value must be numeric', 'Invalid value');
    waitfor(hDlg)
    shoulderGui_changeAngle(fig)
    return
end

if newAngle < -45 || newAngle > 45
    hDlg = errordlg('The value must be between -45 and +45', 'Invalid value');
    waitfor(hDlg)
    shoulderGui_changeAngle(fig)
    return
end

if newAngle == curAngle
    return
end

rectangleS.angle = newAngle;
shoulderGui_setActiveRectangleData(rectangleS, fig)

x0 = get(rectangleS.ll, 'XData');
y0 = get(rectangleS.ll, 'YData');
x1 = get(rectangleS.ur, 'XData');
y1 = get(rectangleS.ur, 'YData');

lineCoords = shoulderGui_getRectangleLineCoords(x0, y0, x1, y1, newAngle);
set(rectangleS.ll2ul, 'XData', lineCoords.ll2ul.x, 'YData', lineCoords.ll2ul.y)
set(rectangleS.ll2lr, 'XData', lineCoords.ll2lr.x, 'YData', lineCoords.ll2lr.y)
set(rectangleS.lr2ur, 'XData', lineCoords.lr2ur.x, 'YData', lineCoords.lr2ur.y)
set(rectangleS.ul2ur, 'XData', lineCoords.ul2ur.x, 'YData', lineCoords.ul2ur.y)
set(rectangleS.ur, 'XData', lineCoords.ur.x, 'YData', lineCoords.ur.y)

set(rectangleS.hLabel, 'Position', [mean(lineCoords.ul2ur.x), mean(lineCoords.ul2ur.y), 0])
set(rectangleS.hLabel, 'Rotation', -newAngle)

end  % #changeAngle
%__________________________________________________________
%% #clearRectangle
%
function shoulderGui_clearRectangle(fig)

if isempty(getAppData(fig, 'rectangle'))
    return
end

rectangleS = shoulderGui_getActiveRectangle(fig, '-doDelete');

delete([rectangleS.ll2ul, rectangleS.ll2lr,...
    rectangleS.lr2ur, rectangleS.ul2ur,...
    rectangleS.ll, rectangleS.ur, rectangleS.hLabel])

curID = getAppData(fig, 'curRectangleID');
if curID == 1
    newID = 0;
else
    subs = getAppData(fig, 'rectangle.subs');
    newID = numel(subs) + 1;
end
setAppData(fig, newID,'curRectangleID');

drawnow

end  % #clearRectangle
%__________________________________________________________
%% #rectangleCornersSwitch
%
function shoulderGui_rectangleCornersSwitch(appData, doShow)

rectangles = cell(1+numel(appData.rectangle.subs),1);
rectangles{1} = appData.rectangle;
for ii = 1:numel(appData.rectangle.subs)
    rectangles{ii+1} = appData.rectangle.subs(ii);
end % for ii

for ii = 1:numel(rectangles)
    if doShow
        if numel(rectangles) == 1 || ii > 1
            set(rectangles{ii}.ll, 'ButtonDownFcn', @shoulderGui_rectangleCornerCB)
            set(rectangles{ii}.ur, 'ButtonDownFcn', @shoulderGui_rectangleCornerCB)
        end
        set(rectangles{ii}.ll, 'Marker', shoulderGui_getDrawPrp(appData, 'pointMarker'))
        set(rectangles{ii}.ur, 'Marker', shoulderGui_getDrawPrp(appData, 'pointMarker'))
        uistack(rectangles{ii}.ll, 'top')
        uistack(rectangles{ii}.ur, 'top')
    else
        set(rectangles{ii}.ll, 'Marker', 'none')
        set(rectangles{ii}.ur, 'Marker', 'none')
        set(rectangles{ii}.ll, 'ButtonDownFcn', '')
        set(rectangles{ii}.ur, 'ButtonDownFcn', '')
    end
end % for ii

end  % #checkRectangle
%__________________________________________________________
%% #drawRectangle
%
function shoulderGui_drawRectangle(fig, x0, y0, x1, y1, angle, label, varargin)

appData = getAppData(fig);

rectangleS = struct;

if ~isempty(varargin) && isstruct(varargin{1})
    lineCoords = varargin{1};
else
    lineCoords = shoulderGui_getRectangleLineCoords(x0, y0, x1, y1, angle);
end

lnPrp           = struct;
lnPrp.Parent    = appData.ax;
lnPrp.LineWidth = shoulderGui_getDrawPrp(appData, 'lineWidth');
lnPrp.Color     = shoulderGui_getDrawPrp(appData, 'lineColor');
lnPrp.lineStyle = shoulderGui_getDrawPrp(appData, 'lineStyle');

lnPrp.XData     = lineCoords.ll2ul.x;
lnPrp.YData     = lineCoords.ll2ul.y;
rectangleS.ll2ul = line(lnPrp);

lnPrp.XData     = lineCoords.ll2lr.x;
lnPrp.YData     = lineCoords.ll2lr.y;
rectangleS.ll2lr = line(lnPrp);

lnPrp.XData     = lineCoords.lr2ur.x;
lnPrp.YData     = lineCoords.lr2ur.y;
rectangleS.lr2ur = line(lnPrp);

lnPrp.XData     = lineCoords.ul2ur.x;
lnPrp.YData     = lineCoords.ul2ur.y;
rectangleS.ul2ur = line(lnPrp);

pointPrp0 = struct;
pointPrp0.Parent             = appData.ax;
pointPrp0.Marker             = shoulderGui_getDrawPrp(appData, 'pointMarker');
pointPrp0.MarkerSize         = shoulderGui_getDrawPrp(appData, 'pointMarkerSize');
pointPrp0.MarkerEdgeColor    = shoulderGui_getDrawPrp(appData, 'pointMarkerEdgeColor');
pointPrp0.MarkerFaceColor    = shoulderGui_getDrawPrp(appData, 'pointMarkerFaceColor');

pointPrp        = pointPrp0;
pointPrp.XData  = x0;
pointPrp.YData  = y0;
rectangleS.ll = line(pointPrp);

pointPrp        = pointPrp0;
pointPrp.XData  = lineCoords.ur.x;
pointPrp.YData  = lineCoords.ur.y;
rectangleS.ur = line(pointPrp);

textPrp           = struct;
textPrp.Parent    = appData.ax;
textPrp.Color     = [206, 130, 0]/255;
textPrp.String    = label;
textPrp.FontSize  = 18;
textPrp.Position  = [mean(lineCoords.ul2ur.x), mean(lineCoords.ul2ur.y),0];
textPrp.Rotation  = -angle;
textPrp.HorizontalAlignment = 'center';
textPrp.VerticalAlignment = 'bottom';

rectangleS.hLabel = text(textPrp);

rectangleS.angle = angle;
rectangleS.label = label;

shoulderGui_setActiveRectangleData(rectangleS, fig)

end  % #drawRectangle
%__________________________________________________________
%% #getDrawPrp
%
function value = shoulderGui_getDrawPrp(appData, name)

if appData.curRectangleID == 1
    prpStruct = appData.rectanglePrps.main;
    isSub = false;
else
    prpStruct = appData.rectanglePrps.sub;
    isSub = true;
end

switch name
    case 'lineStyle'
        if isSub
            ind = mod(appData.curRectangleID-1,numel(prpStruct.line.styles));
            if ind == 0
                ind = numel(prpStruct.line.styles);
            end
            value = prpStruct.line.styles{ind};
        else
            value = '-';
        end
    case 'lineWidth'
        value = prpStruct.line.width;
    case 'lineColor'
        if isSub
            ind = mod(appData.curRectangleID-1,size(prpStruct.line.colors,1));
            if ind == 0
                ind = size(prpStruct.line.colors,1);
            end
            value = prpStruct.line.colors(ind,:);
        else
            value = prpStruct.line.color;
        end
    case 'pointMarker'
        value = prpStruct.point.marker;
    case 'pointMarkerSize'
        value =prpStruct.point.markerSize;
    case 'pointMarkerEdgeColor'
        value = prpStruct.point.markerEdgeColor;
    case 'pointMarkerFaceColor'
        value = prpStruct.point.markerFaceColor;
    case 'pointMarkerFaceColorSelected'
        value = prpStruct.point.markerFaceColorSelected;
    otherwise
        error('.')
end % switch

end  % #getDrawPrp
%__________________________________________________________
%% #getRectangleLineCoords
%
function lineCoords = shoulderGui_getRectangleLineCoords(x0, y0, x1, y1, angle)

% angle is always between (-45, +45) degrees

lineCoords = struct('ll2ul', struct, 'll2lr', struct, 'lr2ur', struct, 'ul2ur', struct);

if angle == 0
    lineCoords.ll2ul.x = [1,1]*x0;
    lineCoords.ll2ul.y = [y0,y1];
    
    lineCoords.ll2lr.x = [x0,x1];
    lineCoords.ll2lr.y = [1,1]*y0;
    
    lineCoords.lr2ur.x = [1,1]*x1;
    lineCoords.lr2ur.y = [y0,y1];
    
    lineCoords.ul2ur.x = [x0,x1];
    lineCoords.ul2ur.y = [1,1]*y1;
    
    lineCoords.ur.x = x1;
    lineCoords.ur.y = y1;
else
    R = [cosd(angle), -sind(angle);sind(angle), cosd(angle)];
    llNorm = [0; 0];
    lrNorm = [x1 - x0; 0];
    ulNorm = [0; y1 - y0];
    urNorm = [x1 - x0; y1 - y0];
    
    llRot = R*llNorm + [x0; y0];
    lrRot = R*lrNorm + [x0; y0];
    ulRot = R*ulNorm + [x0; y0];
    urRot = R*urNorm + [x0; y0];
    
    lineCoords.ll2ul.x = [llRot(1),ulRot(1)];
    lineCoords.ll2ul.y = [llRot(2),ulRot(2)];
    
    lineCoords.ll2lr.x = [llRot(1),lrRot(1)];
    lineCoords.ll2lr.y = [llRot(2),lrRot(2)];
    
    lineCoords.lr2ur.x = [lrRot(1),urRot(1)];
    lineCoords.lr2ur.y = [lrRot(2),urRot(2)];
    
    lineCoords.ul2ur.x = [ulRot(1),urRot(1)];
    lineCoords.ul2ur.y = [ulRot(2),urRot(2)];
    
    lineCoords.ur.x = urRot(1);
    lineCoords.ur.y = urRot(2);
end

end  % #getRectangleLineCoords
%__________________________________________________________
%% #checkGroupNames
%
function [ok, appData] = shoulderGui_checkGroupNames(appData)

ok = false;
pnlData = getAppData(appData.imgPnl);

groupNm1 = get(pnlData.group1Edit, 'String');
groupNm2 = get(pnlData.group2Edit, 'String');

if isempty(groupNm1)
    errordlg('The name of group 1 cannot be empty!', 'Invalid name')
    return
end
if isempty(groupNm2)
    errordlg('The name of group 2 cannot be empty!', 'Invalid name')
    return
end
if strcmpi(groupNm1, groupNm2)
    errordlg('The names must be unique!', 'Invalid names')
    return
end

appData.groups(1).name = groupNm1;
appData.groups(2).name = groupNm2;

ok = true;

end  % #checkGroupNames
%__________________________________________________________
%% #updateGroupNamesInCtrlPnl
%
function shoulderGui_updateGroupNamesInCtrlPnl(fig, groups)

pnlData = getAppData(getAppData(fig, 'ctrlPnl'));

set(pnlData.(pnlData.firstGroupName), 'String',...
    sprintf('%s %s', pnlData.groupBaseStr, groups(1).name))
set(pnlData.(pnlData.secondGroupName), 'String',...
    sprintf('%s %s', pnlData.groupBaseStr, groups(2).name))

end  % #updateGroupNamesInCtrlPnl
%__________________________________________________________
%% #addShoulderPoint
%
function shoulderGui_addShoulderPoint(h, evd)

fig = hfigure(h);
% Deselect any selected point
if ~isempty(getAppData(fig, 'selectedPoint'))
    shoulderGui_switchPointSelection(getAppData(fig, 'selectedPoint'), fig, false)
end

appData = getAppData(fig);

if appData.nextIsSecondPoint
    x1 = get(appData.lastCreatedPoint, 'XData');
    y1 = get(appData.lastCreatedPoint, 'YData');
    x2 = evd.IntersectionPoint(1);
    y2 = evd.IntersectionPoint(2);
    
    % Create connecting line
    lnPpr               = appData.shoulderLinePrp;
    lnPpr.XData         = [x1, x2];
    lnPpr.YData         = [y1, y2];
    connLine            = line(lnPpr);
    
    % Create right should point
    lnPpr = appData.rightShoulderPointPrp;
    lnPpr.XData = x2;
    lnPpr.YData = y2;
    point = line(lnPpr);
    
    uistack(appData.lastCreatedPoint,'top')
    drawnow
    
    % Add line and point to userdata points
    set(point, 'UserData', [appData.lastCreatedPoint, connLine, gobjects(1)])
    set(appData.lastCreatedPoint, 'UserData', [point, connLine, gobjects(1)])
    
    appData.activeShoulderPoints(end+1) = appData.lastCreatedPoint;
    
    appData.nextIsSecondPoint = false;
    appData.lastCreatedPoint = '';
else
    lnPpr = appData.leftShoulderPointPrp;
    lnPpr.XData = evd.IntersectionPoint(1);
    lnPpr.YData = evd.IntersectionPoint(2);
    point = line(lnPpr);
    
    appData.nextIsSecondPoint = true;
    appData.lastCreatedPoint = point;
end

setAppData(fig, appData)

end  % #addShoulderPoint
%__________________________________________________________
%% #shoulderPointCB
%
function shoulderGui_shoulderPointCB(h, evd)

fig = hfigure(h);

% Deselect any selected point
if ~isempty(getAppData(fig, 'selectedPoint'))
    shoulderGui_switchPointSelection(getAppData(fig, 'selectedPoint'), fig, false)
end

if evd.Button == 1
    % Capture current location
    setAppData(fig, {get(h, 'XData');get(h, 'YData')}, 'curPointLoc');
    % left click == start moving point
    set(fig, 'WindowButtonMotionFcn', {@shoulderGui_moveShoulderPoint, h})
    set(fig, 'WindowButtonUpFcn', {@shoulderGui_endMoveShoulderPoint, fig, h})
elseif evd.Button == 3
    appData = getAppData(fig);
    %    right click == remove point (and the connected point and ocnnecting line)
    if h == appData.lastCreatedPoint
        appData.nextIsSecondPoint = false;
        appData.lastCreatedPoint = '';
    end
    userData = get(h, 'UserData');
    if ~isempty(userData)
        delete(userData(1));
        delete(userData(2));
        if ishghandle(userData(3))
            delete(userData(3));
        end
    end
    appData = shoulderGui_removeShoulderPoint(h, appData);
    setAppData(fig, appData)
end

end  % #shoulderPointCB
%__________________________________________________________
%% #removeShoulderPoint
%
function appData = shoulderGui_removeShoulderPoint(h, appData)

for ii = 1:numel(appData.activeShoulderPoints)
    userData = get(h, 'UserData');
    if appData.activeShoulderPoints(ii) == h || (numel(userData) > 0 && appData.activeShoulderPoints(ii) == userData(1))
        appData.activeShoulderPoints(ii) = [];
        break;
    end
end % for ii

delete(h)

end  % #removeShoulderPoint
%__________________________________________________________
%% #moveShoulderPoint
%
function shoulderGui_moveShoulderPoint(h, evd, hPoint)

x = evd.IntersectionPoint(1);
y = evd.IntersectionPoint(2);

set(hPoint, 'XData', x, 'YData', y)
userData = get(hPoint, 'UserData');
if isempty(userData)
    return
end

otherPoint = userData(1);
xOther = get(otherPoint, 'XData');
yOther = get(otherPoint, 'YData');
connLine = userData(2);
set(connLine, 'XData', [x, xOther], 'YData', [y, yOther])

if ishghandle(userData(3))
    set(userData(3), 'Position', [mean([x, xOther]), 'YData', mean([y, yOther]), 0])
end

end  % #moveShoulderPoint
%__________________________________________________________
%% #endMoveShoulderPoint
%
function shoulderGui_endMoveShoulderPoint(h, evd, fig, hPoint)

set(fig, 'WindowButtonMotionFcn', '')
set(fig, 'WindowButtonUpFcn', '')
curPointLoc = getAppData(fig, 'curPointLoc');
if all(curPointLoc{1} == get(hPoint, 'XData')) && all(curPointLoc{2} == get(hPoint, 'YData'))
    setAppData(fig, {}, 'curPointLoc')
    % Activate point
    shoulderGui_switchPointSelection(hPoint, fig, true) % Sometimes gives an error
    
    return
end

end  % #endMoveShoulderPoint
%__________________________________________________________
%% #saveShoulderData
%
function appData = shoulderGui_saveShoulderData(appData, groupInd, stepInd)

lastCreatedInList = false;
appData.selectedPoint = [];

for ii = 1:numel(appData.activeShoulderPoints)
    if appData.lastCreatedPoint == appData.activeShoulderPoints(ii)
        lastCreatedInList = true;
    end
    if groupInd == 1
        userData = get(appData.activeShoulderPoints(ii), 'UserData');
        set(appData.activeShoulderPoints(ii), 'MarkerFaceColor', appData.inactiveShoulderPointColor)
        set(userData(1), 'MarkerFaceColor', appData.inactiveShoulderPointColor)
        set(appData.activeShoulderPoints(ii), 'MarkerSize', appData.baseMarkerSize)
        set(userData(1), 'MarkerSize', appData.baseMarkerSize)
        set(userData(2), 'Color', appData.inactiveShoulderLineColor)
        set(appData.activeShoulderPoints(ii), 'ButtonDownFcn', '')
        set(userData(1), 'ButtonDownFcn', '')
    end
end % for ii

if groupInd == 1
    appData = shoulderGui_addPointsToData(appData, 1, stepInd, appData.activeShoulderPoints);
end
if groupInd == 2
    appData = shoulderGui_addPointsToData(appData, 1, stepInd, appData.inactiveShoulderPoints);
    appData = shoulderGui_addPointsToData(appData, 2, stepInd, appData.activeShoulderPoints);
    shoulderGui_deletePoints(appData.activeShoulderPoints)
    shoulderGui_deletePoints(appData.inactiveShoulderPoints)
end

if ~lastCreatedInList && ~isempty(appData.lastCreatedPoint)
    delete(appData.lastCreatedPoint)
end

if groupInd == 1
    if ~isempty(appData.inactiveShoulderPoints)
        appData = shoulderGui_activatePoints(appData);
    else
        appData.inactiveShoulderPoints = appData.activeShoulderPoints;
        appData.activeShoulderPoints = gobjects(0);
    end
else
    appData.inactiveShoulderPoints = gobjects(0);
end

appData.nextIsSecondPoint = false;
appData.lastCreatedPoint = '';
drawnow

end  % #saveShoulderData
%__________________________________________________________
%% #deletePoints
%
function shoulderGui_deletePoints(points)

for ii = 1:numel(points)
    userData = get(points(ii), 'UserData');
    delete(userData(1));
    delete(userData(2))
    if ishghandle(userData(3))
        delete(userData(3))
    end
    delete(points(ii))
end % for ii

end  % #deletePoints
%__________________________________________________________
%% #addPointsToData
%
function appData = shoulderGui_addPointsToData(appData, groupInd, stepInd, points)

dataInd = appData.stepInd2dataInd(stepInd);

appData.groups(groupInd).shoulders{dataInd,1} = (stepInd - 1)*appData.interval + 1;
appData.groups(groupInd).shoulders{dataInd,2} = numel(points);

pointData = nan(numel(points), 5);

for ii = 1:numel(points)
    userData = get(points(ii), 'UserData');
    pointData(ii,1) = get(points(ii), 'XData');
    pointData(ii,2) = get(points(ii), 'YData');
    pointData(ii,3) = get(userData(1), 'XData');
    pointData(ii,4) = get(userData(1), 'YData');
    if ishghandle(userData(3))
        pointData(ii,5) = double(get(userData(3), 'String')) - 64;
    end
end % for ii

appData.groups(groupInd).shoulders{dataInd,3} = pointData;

end  % #addPointsToData
%__________________________________________________________
%% #activatePoints
%
function appData = shoulderGui_activatePoints(appData)

inactivePoints = appData.inactiveShoulderPoints;
appData.inactiveShoulderPoints = appData.activeShoulderPoints;
appData.activeShoulderPoints = inactivePoints;
appData.selectedPoint = [];

for ii = 1:numel(inactivePoints)
    userData = get(inactivePoints(ii), 'UserData');
    set(inactivePoints(ii), 'MarkerFaceColor', appData.leftShoulderPointColor)
    set(userData(1), 'MarkerFaceColor', appData.rightShoulderPointColor)
    set(inactivePoints(ii), 'MarkerSize', appData.baseMarkerSize)
    set(userData(1), 'MarkerSize', appData.baseMarkerSize)
    set(userData(2), 'Color', appData.activeShoulderLineColor)
    set(inactivePoints(ii), 'ButtonDownFcn', @shoulderGui_shoulderPointCB)
    set(userData(1), 'ButtonDownFcn', @shoulderGui_shoulderPointCB)
end % for ii

end  % #activatePoints
%__________________________________________________________
%% #setPointsBasedOnData
%
function appData = shoulderGui_setPointsBasedOnData(appData)

if appData.minorStepInd == 1
    firstActive = true;
    secondActive = false;
else
    secondActive = true;
    firstActive = false;
end

dataInd = appData.stepInd2dataInd(appData.analysisStepInd);

if appData.groups(1).shoulders{dataInd,2} > 0
    % Create active points
    pointData = appData.groups(1).shoulders{dataInd,3};
    firstGroupPoint = shoulderGui_createPointsFromData(pointData, firstActive, appData);
else
    firstGroupPoint = gobjects(0);
end
if appData.groups(2).shoulders{dataInd,2} > 0
    % Create inactive points
    pointData = appData.groups(2).shoulders{dataInd,3};
    secondGroupPoints = shoulderGui_createPointsFromData(pointData, secondActive, appData);
else
    secondGroupPoints = gobjects(0);
end

if appData.minorStepInd == 1
    appData.activeShoulderPoints = firstGroupPoint;
    appData.inactiveShoulderPoints = secondGroupPoints;
else
    appData.activeShoulderPoints = secondGroupPoints;
    appData.inactiveShoulderPoints = firstGroupPoint;
end

end  % #setPointsBasedOnData
%__________________________________________________________
%% #createPointsFromData
%
function points = shoulderGui_createPointsFromData(pointData, isActive, appData)

points = gobjects(size(pointData,1),1);
for ii = 1:size(pointData,1)
    lnPpr               = appData.shoulderLinePrp;
    lnPpr.XData         = [pointData(ii,1), pointData(ii,3)];
    lnPpr.YData         = [pointData(ii,2), pointData(ii,4)];
    if ~isActive
        lnPpr.Color     = appData.inactiveShoulderLineColor;
    end
    connLine            = line(lnPpr);
    
    lnPpr = appData.leftShoulderPointPrp;
    if ~isActive
        lnPpr.MarkerFaceColor = appData.inactiveShoulderPointColor;
        lnPpr.ButtonDownFcn = '';
    end
    lnPpr.XData = pointData(ii,1);
    lnPpr.YData = pointData(ii,2);
    leftPoint = line(lnPpr);
    
    lnPpr = appData.rightShoulderPointPrp;
    if ~isActive
        lnPpr.MarkerFaceColor = appData.inactiveShoulderPointColor;
        lnPpr.ButtonDownFcn = '';
    end
    lnPpr.XData = pointData(ii,3);
    lnPpr.YData = pointData(ii,4);
    rightPoint = line(lnPpr);
    
    if ~isnan(pointData(ii,5))
        shoulderTextPrp = appData.shoulderTextPrp;
        shoulderTextPrp.String = char(64 + pointData(ii,5));
        shoulderTextPrp.Position = [mean(pointData(ii,[1,3])), mean(pointData(ii,[2,4])), 0];
        hText = text(shoulderTextPrp);
    else
        hText = gobjects(1);
    end
    
    set(leftPoint, 'UserData', [rightPoint, connLine, hText])
    set(rightPoint, 'UserData', [leftPoint, connLine, hText])
    points(ii) = leftPoint;
end % for ii

end  % #createPointsFromData
%__________________________________________________________
%% #clearPoints
%
function appData = shoulderGui_clearPoints(appData)

shoulderGui_deletePoints(appData.activeShoulderPoints)
shoulderGui_deletePoints(appData.inactiveShoulderPoints)
appData.activeShoulderPoints = gobjects(0);
appData.inactiveShoulderPoints = gobjects(0);

end  % #clearPoints
%__________________________________________________________
%% #initSaveFile
%
function appData = shoulderGui_initSaveFile(appData)

if ~isempty(appData.dataFilename)
   filename = appData.dataFilename;
else
    filename = shoulderGui_chooseSaveFilename();
    appData.dataFilename = filename;
end

appData.dataFile = matfile(filename,'Writable',true);

end  % #initSaveFile
%__________________________________________________________
%% #saveData2file
%
function shoulderGui_saveData2file(appData, field)

switch field
    case 'all'
        shoulderGui_saveData2file(appData, 'videoData')
        shoulderGui_saveData2file(appData, 'interval')
        shoulderGui_saveData2file(appData, 'rectangle')
        shoulderGui_saveData2file(appData, 'groups')
        data = load(appData.dataFilename);
        save(appData.dataFilename, '-struct', 'data');
    case 'videoData'
        videoSaveData = struct;
        if isempty(appData.videoData)
            return
        end
        videoSaveData.frameRate = appData.videoData.vidObj.FrameRate;
        videoSaveData.duration = appData.videoData.vidObj.Duration;
        videoSaveData.filename = appData.videoData.flNm;
        appData.dataFile.video = videoSaveData;
    case 'interval'
        appData.dataFile.analysisStepCount = appData.analysisStepCount;
        appData.dataFile.interval = appData.interval;
    case 'rectangle'
        rectangleSaveData = struct;
        rectangleSaveData.main = shoulderGui_getRectangleSaveData(appData.rectangle);
        if isfield(appData.rectangle, 'subs') && numel(appData.rectangle.subs)
            subs = shoulderGui_getRectangleSaveData(appData.rectangle.subs(1));
            for ii = 2:numel(appData.rectangle.subs)
                subs(ii) = shoulderGui_getRectangleSaveData(appData.rectangle.subs(ii));
            end % for ii
        else
            subs = struct([]);
        end        
        rectangleSaveData.subs = subs;        
        appData.dataFile.rectangle = rectangleSaveData;
    case 'groups'
        appData.dataFile.groups = appData.groups;
    otherwise
        error('Unknown field: %s', field)
end

end  % #saveData2file
%__________________________________________________________
%% #getRectangleSaveData
%
function saveData = shoulderGui_getRectangleSaveData(rectangleData)

lineFields = {'ll2ul', 'll2lr', 'lr2ur', 'ul2ur', 'll', 'ur'};

saveData = struct;
if ~isfield(rectangleData, 'label')
    saveData.label = 'Main';
else
    saveData.label = rectangleData.label;
end
if ~isfield(rectangleData, 'label')
    saveData.angle = 0;
else
    saveData.angle = rectangleData.angle;
end

for ii = 1:numel(lineFields)
    geomData = struct('x', [], 'y', []);
    geomData.x = get(rectangleData.(lineFields{ii}), 'XData');
    geomData.y = get(rectangleData.(lineFields{ii}), 'YData');
    saveData.(lineFields{ii}) = geomData;    
end % for ii

end  % #getRectangleSaveData
%__________________________________________________________
%% #chooseSaveFilename
%
function filename = shoulderGui_chooseSaveFilename()

[file, path] = uiputfile('*.mat', 'Choose a file for saving', 'shoulderData.mat');
if file == 0
    hDlg = warndlg('A save file must be chosen to continue!', 'Warning', '-modal');
    waitfor(hDlg)
    filename = shoulderGui_chooseSaveFilename();
else
    filename = fullfile(path, file);
end

end  % #chooseSaveFilename
%__________________________________________________________
%% #checkShoulders
%
function appData = shoulderGui_checkShoulders(appData)

if size(appData.groups(1).shoulders, 1) == appData.analysisStepCount
    return
end

frameNrsInData = appData.groups(1).shoulders(:,1);
emptyInd = cellfun(@isempty,frameNrsInData);
frameNrsInData(emptyInd) = {NaN};
frameNrsInData = cell2mat(frameNrsInData);
frameNrPerStep = 1:appData.interval:appData.interval*appData.analysisStepCount;
[diffNr, diffInd] = setdiff(frameNrsInData, frameNrPerStep);
otherInd = diffInd(~isnan(diffNr));

appData.stepInd2dataInd = setdiff(1:size(appData.groups(1).shoulders, 1), otherInd);

end  % #checkShoulders
%__________________________________________________________
%% #convertToFrameNr
%
function shoulderGui_convertToFrameNr(filename)

data = load(filename);

for ii = 1:numel(data.groups)
    for jj = 1:size(data.groups(ii).shoulders,1)
        data.groups(ii).shoulders{jj,1} = (data.groups(ii).shoulders{jj,1} - 1)*data.interval + 1;
    end % for jj
end % for ii

save(filename, '-struct', 'data')

end  % #convertToFrameNr
%__________________________________________________________
%% #setActiveRectangle
%
function shoulderGui_setActiveRectangle(fig, hCorner)

rectangle = getAppData(fig, 'rectangle');
if hCorner == rectangle.ll || hCorner == rectangle.ur
    newID = 1;
else
    for ii = 1:numel(rectangle.subs)
        if hCorner == rectangle.subs(ii).ll || hCorner == rectangle.subs(ii).ur
            newID = 1 + ii;
            break
        end
    end % for ii
end
setAppData(fig, newID , 'curRectangleID');

end  % #setActiveRectangle
%__________________________________________________________
%% #getActiveRectangle
%
function rectangleS = shoulderGui_getActiveRectangle(fig, varargin)

if any(strcmpi(varargin, '-doDelete'))
    doDelete = true;
else
    doDelete = false;
end

curID = getAppData(fig, 'curRectangleID');
rectangle = getAppData(fig, 'rectangle');

if curID == 1
    rectangleS = rectangle;
else
    rectangleS = rectangle.subs(curID-1);
end

if doDelete
    if curID == 1
        setAppData(fig, '', 'rectangle');
        return
    else
        if numel(rectangle.subs) == 1
            setAppData(fig, struct([]), 'rectangle.subs');
            toDelete = 1;
            toLower = [];
        else
            for ii = curID-1:numel(rectangle.subs)
                rectangle.subs(ii).label = char(64 + ii - 1);
                set(rectangle.subs(ii).hLabel, 'String', rectangle.subs(ii).label)
            end % for ii
            rectangle.subs(curID-1) = [];
            setAppData(fig, rectangle, 'rectangle');
            toDelete = curID-1;
            toLower = curID:numel(rectangle.subs);
        end
    end
    groups = getAppData(fig, 'groups');
    for jj = 1:2
        if isempty(groups(jj).shoulders)
            continue
        end
        for kk = 1:size(groups(jj).shoulders,1)
            if isempty(groups(jj).shoulders{kk,3})
                continue
            end
            pointData = groups(jj).shoulders{kk,3};
            pointData(pointData(:,5) == toDelete, 5) = NaN;
            for ii = numel(toLower)
                pointData(pointData(:,5) == toLower(ii), 5) = pointData(pointData(:,5) == toLower(ii), 5) - 1;
            end % for ii
            groups(jj).shoulders{kk,3} = pointData;
        end % for kk
    end % for jj
    setAppData(fig, groups, 'groups');
end

end  % #getActiveRectangle
%__________________________________________________________
%% #setActiveRectangleData
%
function shoulderGui_setActiveRectangleData(rectangleS, fig)

curID = getAppData(fig, 'curRectangleID');
rectangle = getAppData(fig, 'rectangle');

if curID == 1
    fldNms = fieldnames(rectangleS);
    for ii = 1:numel(fldNms)
        rectangle.(fldNms{ii}) = rectangleS.(fldNms{ii});
    end % for ii
    if ~isfield(rectangle, 'subs')
        rectangle.subs = struct([]);
    end
    if ~isfield(rectangle, 'activePoint')
        rectangle.activePoint = '';
    end
else
    if numel(rectangle.subs)
        rectangle.subs(curID-1) = rectangleS;
    else
        rectangle.subs = rectangleS;
    end
end

setAppData(fig, rectangle, 'rectangle');

end  % #setActiveRectangleData
%__________________________________________________________
%% #addRectangleFromData
%
function shoulderGui_addRectangleFromData(fig, rectangleS)

x0 = rectangleS.ll.x;
y0 = rectangleS.ll.y;
x1 = rectangleS.ur.x;
y1 = rectangleS.ur.y;

angle = rectangleS.angle;
label = rectangleS.label;

fldNms2omit = {'label', 'angle'};
fldNms = setdiff(fieldnames(rectangleS), fldNms2omit);
lineCoords = struct;
for ii = 1:numel(fldNms)
    lineCoords.(fldNms{ii}).x = rectangleS.(fldNms{ii}).x;
    lineCoords.(fldNms{ii}).y = rectangleS.(fldNms{ii}).y;
end % for ii
shoulderGui_drawRectangle(fig, x0, y0, x1, y1, angle, label, lineCoords);

end  % #addRectangleFromData
%__________________________________________________________
%% #switchPointSelection
%
function shoulderGui_switchPointSelection(hPoint, fig, isSelected)

if isSelected
    userData = get(hPoint, 'UserData');
    if isempty(userData)
        return
    end
    
    setAppData(fig, hPoint, 'selectedPoint')
    % Make point selected visually
    markerSize = getAppData(fig, 'selectedMarkerSize');
    % Add keypressfcn
    set(fig, 'WindowKeyPressFcn', @shoulderGui_shoulderKeyPress)
else
    markerSize = getAppData(fig, 'baseMarkerSize');
    set(fig, 'WindowKeyPressFcn', '')
    setAppData(fig, [], 'selectedPoint')
end

set(hPoint, 'MarkerSize', markerSize)
userData = get(hPoint, 'UserData');
otherPoint = userData(1);
set(otherPoint, 'MarkerSize', markerSize)

end  % #switchPointSelection
%__________________________________________________________
%% #shoulderKeyPress
%
function shoulderGui_shoulderKeyPress(h, evd)

fig = hfigure(h);
rectangle = getAppData(fig, 'rectangle');
if ~numel(rectangle.subs)
    return
end
keys = {rectangle.subs.label};

if ~(any(strcmpi(evd.Key, keys)) || strcmpi(evd.Key, 'delete'))
    return
end

hPoint = getAppData(fig, 'selectedPoint');
userData = get(hPoint, 'UserData');
otherPoint = userData(1);
otherUserData = get(otherPoint, 'UserData');

if strcmpi(evd.Key, 'delete')
    % Delete label
    if ishghandle(userData(3))
        delete(userData(3))
        userData(3) = gobjects(1);
        otherUserData(3) = gobjects(1);
    end
else
    x = get(hPoint, 'XData');
    y = get(hPoint, 'YData');
    
    xOther = get(otherPoint, 'XData');
    yOther = get(otherPoint, 'YData');
    
    shoulderTextPrp = getAppData(fig, 'shoulderTextPrp');
    shoulderTextPrp.String = upper(evd.Key);
    shoulderTextPrp.Position = [mean([x, xOther]), mean([y, yOther]), 0];
    hText = text(shoulderTextPrp);
    
    otherUserData(3) = hText;
    userData(3) = hText;
end
set(hPoint, 'UserData', userData);
set(otherPoint, 'UserData', otherUserData);

shoulderGui_switchPointSelection(hPoint, fig, false)

end  % #shoulderKeyPress
%__________________________________________________________
%% #convertOldMat2new
%
function shoulderGui_convertOldMat2new(filename)

data = load(filename);

appData = struct;
fldNms = fieldnames(data);
for ii = 1:numel(fldNms)
    appData.(fldNms{ii}) = data.(fldNms{ii});        
end % for ii

appData.videoData.vidObj = struct;
appData.videoData.vidObj.FrameRate = appData.video.frameRate;
appData.videoData.vidObj.Duration = appData.video.duration;
appData.videoData.flNm = appData.video.filename;

appData.dataFilename = filename;

delete(filename)
appData = shoulderGui_initSaveFile(appData);
shoulderGui_saveData2file(appData, 'all')
data = load(filename);
save(filename, '-struct', 'data');

end  % #convertOldMat2new
%__________________________________________________________
%% #qqq
%
function shoulderGui_qqq

end  % #qqq
%__________________________________________________________
%% #rrr
%
function varargout = shoulderGui_rrr(action, varargin)

if nargout
    varargout = cell(1, nargout);
end

switch action
    case 'fcnHandle'
        varargout{1} = eval(['@shoulderGui_rrr_', varargin{1}]);
    case 'sss'
        
    otherwise
        error('.')
end

% _________________________________________________________
% _rrr_sub1
    function shoulderGui_rrr_sub1
        
    end  % _rrr_sub1

end  % #rrr
%__________________________________________________________