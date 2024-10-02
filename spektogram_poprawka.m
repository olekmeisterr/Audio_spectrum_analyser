clc
close all
clear

% Inicjalizacja obiektu oraz podpięcie pinu mikrofonowego
object = arduino('COM3', 'UNO');
micPin = 'A1';
% Parametry wejściowe
fs = 40000; % Częstotliwość próbkowania
measurementDuration = 10; % Łączny czas trwania pomiaru (s)
N = 4096 * measurementDuration ; % Łączna liczba próbek
windowLength = 1024; % Długość okna Hamminga
% Prototyp wektora próbek
data = zeros(N, 1);
% Prototyp wektora czasu
time = (0:(N-1)) / fs;
% Prototyp wektora częstotliwości
f_fft = linspace(0, fs/2, N/2+1);
% Wykres dla sygnału w dziedzinie czasu
figure('Name', 'Sygnał w dziedzinie czasu');
ax_time = axes;
h_time = plot(ax_time, time, zeros(N, 1));
xlabel(ax_time, 'Czas (s)');
ylabel(ax_time, 'Amplituda');
title(ax_time, 'Sygnał w dziedzinie czasu');
grid(ax_time, 'on');
xlim([1 measurementDuration]);
% Odczyt danych oraz analiza w czasie rzeczywistym
start_time = tic; % Start zegara
for i = 1:N
    % Odczyt z mikrofonu
    voltage = readVoltage(object, micPin);
    soundPressureLevel = voltage;
    % Zapis wartości mikrofonu w wektorze data
    data(i) = soundPressureLevel;
    % Mozliwość pomiaru przez określony czas
    elapsed_time = toc(start_time);
    time(i) = elapsed_time;
    % Konwersja amplitudy do jednostek decybeli
    amplituda_dB = 20 * log10(data);
    % Aktualizacja wykresu sygnału w dziedzinie czasu
    set(h_time, 'YData', amplituda_dB, 'XData', time);
    drawnow;
    % Pętla do zakończenia pomiarów po upływie określonego czasu
    if elapsed_time >= measurementDuration
        break;
    end
    % Oczekiwanie na kolejną próbkę
    pause(1/fs); 
end
% Zastosowanie okna Hamminga
data_windowed = data .* hamming(N);
% Parametry filtru górnoprzepustowego
cutoff_frequency = 600;
normalized_cutoff = cutoff_frequency / (fs / 2);
% Zastosowanie filtra górnoprzepustowego
filter_order = 50; 
b = fir1(filter_order, normalized_cutoff, 'high');
cutoff_frequency = 600;
normalized_cutoff = cutoff_frequency / (fs / 2);
b = fir1(filter_order, normalized_cutoff, 'high');
data_filtered = filter(b, 1, data_windowed);
% Analiza widma FFT po zakończeniu pomiarów
Y_filtered = fft(data_filtered, N);   
mag_fft_filtered = abs(Y_filtered(1:N/2+1));
% Wykres dla analizy widmowej FFT po filtracji
figure('Name', 'Analiza widmowa FFT po filtracji');
h_fft_filtered = bar(f_fft, mag_fft_filtered);
xlabel('Częstotliwość (Hz)');
ylabel('Amplituda(dB)');
title('Analiza widmowa w dziedzinie częstotliwości (FFT)');
grid on;
xlim([600, fs/2]); 
% Analiza widmowa przy użyciu spektrogramu
figure('Name', 'Spektrogram');
noverlap = windowLength/2;
ax_spectrogram = axes;
[S,F,T] = spectrogram(Y_filtered, hamming(windowLength), noverlap, [], fs);
% Zaznaczenie zakresu częstotliwości
freq_range = F >= 600 & F <= 20000;
spectrogram_data = 10 * log10(abs(S));
% Uzyskanie wektora czasu
time_vector = linspace(0, measurementDuration, length(T));
% Wyświetlenie spektrogramu
imagesc(ax_spectrogram, time_vector, F(freq_range), spectrogram_data(freq_range, :));
axis xy;
xlabel(ax_spectrogram, 'Czas (s)');
ylabel(ax_spectrogram, 'Częstotliwość (Hz)');
title(ax_spectrogram, 'Spektrogram');
colorbar;