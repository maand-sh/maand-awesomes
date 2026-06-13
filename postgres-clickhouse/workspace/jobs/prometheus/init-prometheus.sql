CREATE DATABASE IF NOT EXISTS metrics;
SET allow_experimental_time_series_table = 1;
CREATE TABLE IF NOT EXISTS metrics.prometheus ENGINE = TimeSeries;