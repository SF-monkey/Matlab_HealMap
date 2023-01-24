function [] = calMSD(maxInterval)
    [fn, fp, index] = uigetfile('*.csv');
    if index == 0
        disp('No file selected!');
    else
        data = importdata(strcat(fp,fn));

        msd = zeros(1,maxInterval);
        for n = 1:1:maxInterval
            displacement = zeros(1000,1);
            for m = (n+1):1:1000
                dx = data(m,1) - data(m-n,1);
                dy = data(m,2) - data(m-n,2);

                displacement(m) = sqrt(dx^2 + dy^2);
            end

            msd(n) = mean(displacement((n+1):1000).^2);
        end

        plot(0.1:0.1:(maxInterval*0.1), msd,...
            'b-s',...
            'LineWidth',2,...
            'MarkerFaceColor','b',...
            'MarkerSize',5)
    end
end

