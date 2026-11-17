% Synthetic thin-band segmentation. Run from a writable folder.
rng(17, 'twister');
[x, y] = meshgrid(1:180, 1:100);
center = 50 + 18 * sin(x / 25);
halfWidth = 1 + 2 * (x - 1) / 179;
reference = abs(y - center) <= halfWidth & x >= 12 & x <= 169;
noisy = 0.2 + 0.6 * double(reference) + 0.16 * randn(size(x));

threshold = 0.5;
windowSize = 3; % Try 3 on your second run.
kernel = ones(windowSize) / windowSize^2;
% Pad with the background intensity when averaging near image edges.
smoothed = 0.2 + conv2(noisy - 0.2, kernel, 'same');
masks = {noisy > threshold, smoothed > threshold};
labels = {'Threshold only', 'Smooth then threshold'};

figure('color', 'white', 'position', [80 80 1000 380]);
subplot(1, 3, 1);
imagesc(noisy, [0 1]);
axis image off;
colormap(gray(256));
title('Synthetic noisy input');
for k = 1:2
    predicted = masks{k};
    overlap = nnz(predicted & reference);
    dice = 2 * overlap / (nnz(predicted) + nnz(reference));
    missed = nnz(reference & ~predicted);
    extra = nnz(predicted & ~reference);
    fprintf('%s: Dice %.3f, missed %d pixels, extra %d pixels\n', ...
        labels{k}, dice, missed, extra);
    % White = overlap, red = missed, blue = extra.
    rgb = cat(3, reference, reference & predicted, predicted);
    subplot(1, 3, k + 1);
    image(double(rgb));
    axis image off;
    title({labels{k}, sprintf('Dice %.3f', dice)});
    xlabel('White: overlap   Red: missed   Blue: extra');
end
filename = sprintf('thin_band_window_%d.png', windowSize);
print(gcf, filename, '-dpng', '-r150');
fprintf('Saved figure: %s\n', fullfile(pwd, filename));
