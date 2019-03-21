% This function requires the psychtoolbox and colorspace libraries.
clear all;

screenX = 500;
screenY = 500;

win = Screen('OpenWindow', 0, [255 255 255], [0 0 screenX screenY]);
Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
petals = {'Components/petal_concave.png'};
centers = {'Components/middle_square.png', 'Components/middle_triangle.png', ...
	   'Components/middle_circle.png', 'Components/middle_star.png'};

screenRct = Screen('Rect', win);
rct = CenterRect([0 0 200 100], screenRct);

sepalNums = 1:3;
petalNums = [4 6 8];
petalColorsF = {'blue', 'pink', 'yellow', 'green'};
centerShapesF = {'square', 'tri', 'circle', 'star'};
centerColorsF = {'purple', 'orange','lightblue','brightgreen'};

petalColorList = [0 90 180 270];
centerColorList = [45 135 225 315];


for petalShape = 1:length(petals)
  for petalColorI = 1:length(petalColorsF)
    petalColor = petalColorList(petalColorI);
    for centerColorI = 1:length(centerColorsF)
      centerColor = centerColorList(centerColorI);
      [petal map alpha] = imread(petals{petalShape});
      petal = double(petal)./255;
      hsv = colorspace('RGB->HSV', petal);
      hue = mod(hsv(:,:,1) + petalColor, 360);
      hsv(:,:,1) = hue;
      petal = colorspace('HSV->RGB',hsv) .* 255;
      petal(:,:,4) = alpha;
      pPetal = Screen('MakeTexture', win, petal);
    
      for centerShape = 1:length(centerShapesF)
        [center map alpha] = imread(centers{centerShape});
        center = double(center)./255;
        hsv = colorspace('RGB->HSV', center);
        hue = mod(hsv(:,:,1) + centerColor, 360);
        hsv(:,:,1) = hue;
        center = colorspace('HSV->RGB',hsv) .* 255;
        center(:,:,4) = alpha;
        pCenter = Screen('MakeTexture', win, center);
      
        for sepalNum = sepalNums
          [sepal map alpha] = imread(['Components/sepal_' num2str(sepalNum) '.png']);
          sepal(:,:,4) = alpha;
          pSepal = Screen('MakeTexture', win, sepal);
        
          for petalNum = petalNums
            Screen('FillRect', win, [255 255 255]);
          
            for k=1:petalNum
              offset = 360/petalNum * (k-1);
              newLeft = cosd(offset)*150 - 3;
              newTop = sind(offset)*150;
              rctOff = OffsetRect(rct, newLeft, newTop);
              Screen('DrawTexture', win, pPetal, [], rctOff, offset);
            end
            for k=1:petalNum
              sepalOffset = 360/petalNum * (k-1) + (360/petalNum)/2;
              newLeft = cosd(sepalOffset)*150 - 3;
              newTop = sind(sepalOffset)*150;
              rctOff = OffsetRect(rct, newLeft, newTop);
              Screen('DrawTexture', win, pSepal, [], rctOff, sepalOffset);
            end
            Screen('DrawTexture', win, pCenter);
            Screen('Flip', win);
            fName = sprintf('images/stim_%d_%s_%s_%s_%d.png', ...
            petalNum, petalColorsF{petalColorI}, ...
            centerShapesF{centerShape}, ...
            centerColorsF{centerColorI}, sepalNum);
            disp(fName);
            imageArray = Screen('GetImage', win, [0 0 500 500]);
            imwrite(imageArray, fName, 'png');
          end
        end
      end
    end
  end
end
Screen('Close', win);
sca;
