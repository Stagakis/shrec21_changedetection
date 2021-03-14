//
// Created by andreas on 16/11/20.
//
#include <pcl/common/io.h>
#include <pcl/point_types.h>
#include <pcl/features/gasd.h>
#include <pcl/point_cloud.h>
#include <pcl/io/openni_grabber.h>
#include <pcl/visualization/cloud_viewer.h>
#include <pcl/common/transforms.h>
#include <pcl/compression/octree_pointcloud_compression.h>
#include <algorithm>
#include <stdio.h>
#include <sstream>
#include <stdlib.h>
#include <iostream>
#include <Eigen/Dense>
#include "filenames.h"
#include <iostream>
#include <utils.h>
#include "Dataset.h"
#include <pcl/features/shot.h>
#include <pcl/visualization/pcl_visualizer.h>
#include <pcl/visualization/cloud_viewer.h>

#include <liblas/liblas.hpp>
#include <fstream>  // std::ifstream
#include <iostream> // std::cout



void removeGround(PointCloud3D::Ptr cloud, pcl::PointXYZ& center, const float& ground_thres){
    int num{0};
    std::vector<pcl::PointXYZRGB> temp_point_storage;
    for (auto&p : cloud->points)
        if (p.z > ground_thres){
            temp_point_storage.push_back(p);
            num++;
        }
    cloud->points.clear();
    cloud->width = num;
    cloud->height = 1;
    cloud->points.resize(cloud->width*cloud->height);
    int index{0};
    for (auto &point : cloud->points) {
        point.x = temp_point_storage[index].x;// - center.x;
        point.y = temp_point_storage[index].y;// - center.y;
        point.z = temp_point_storage[index].z;// - center.z;
        point.r = temp_point_storage[index].r;
        point.g = temp_point_storage[index].g;
        point.b = temp_point_storage[index].b;
        index++;
    }
}

void show_point_cloud(PointCloud3D::Ptr pcld){

    pcl::visualization::CloudViewer viewer ("Simple Cloud Viewer");

    //Eigen::Vector4f centroid;
    //pcl::compute3DCentroid(*pcld,centroid);

    double sum_x=0;
    double sum_y=0;
    double sum_z=0;
    for(int i = 0 ; i < pcld->size(); i++) {
        sum_x += pcld->at(i).x/pcld->size();
        sum_y += pcld->at(i).y/pcld->size();
        sum_z += pcld->at(i).z/pcld->size();
    }

    for(int i = 0 ; i < pcld->size(); i++){
        pcld->at(i).x -= (float)sum_x;
        pcld->at(i).y -= (float)sum_y;
        //pcld->at(i).z -= (float)sum_z;
    }
    //std::cout << "Center of mass: " << sum_x << " " << sum_y << " " << sum_z << std::endl;


    viewer.showCloud (pcld);

    while (!viewer.wasStopped ())
    {
        viewer.showCloud (pcld);

    }
}

typedef std::vector<int> histogram;
void histogramRGB(const PointCloud3D::Ptr &cloud, std::vector<histogram> &hist_rgb){
    const int bin_width = 5;
    const int bin_number = 255/bin_width;
    hist_rgb.clear();
    hist_rgb.emplace_back(bin_number,0);  //Red
    hist_rgb.emplace_back(bin_number,0);  //Green
    hist_rgb.emplace_back(bin_number,0);  //Blue

    for(int i = 0 ; i < cloud->size() ; i++){
        RGBtoHSV(cloud->points[i],cloud->points[i]);

        int bin_index;

        bin_index = std::min(cloud->points[i].r/bin_width, bin_number-1);
        ++hist_rgb[0][bin_index];
        bin_index = std::min(cloud->points[i].g/bin_width, bin_number-1);
        ++hist_rgb[1][bin_index];
        bin_index = std::min(cloud->points[i].b/bin_width, bin_number-1);
        ++hist_rgb[2][bin_index/bin_width];
    }
}

double calculateHistogramDistance(std::vector<histogram> &hist_rgb_2016, std::vector<histogram> &hist_rgb_2020){
    std::vector<double> channel_diff(3, 0.0f); //stores the difference of the histograms per channel
    int bin_number = hist_rgb_2020[0].size();

    int max_index_2016 = std::distance(hist_rgb_2016[2].begin(), std::max_element(hist_rgb_2016[2].begin(), hist_rgb_2016[2].end()));
    int max_index_2020 = std::distance(hist_rgb_2020[2].begin(), std::max_element(hist_rgb_2020[2].begin(), hist_rgb_2020[2].end()));
    auto drift = max_index_2020 - max_index_2016;

    for(int color_channel = 0 ; color_channel< 3; color_channel++){
        auto& hist_2016 = hist_rgb_2016[color_channel];
        int hist_2016_sum = std::accumulate(hist_2016.begin(), hist_2016.end(), 0);
        auto& hist_2020 = hist_rgb_2020[color_channel];
        int hist_2020_sum = std::accumulate(hist_2020.begin(), hist_2020.end(), 0);

        for(int i = 0 ; i < bin_number ; i++) {
            auto shifted_i = std::clamp(i - drift, 0, bin_number-1);

            double bin_2016 = static_cast<double>(hist_2016[shifted_i]);///(std::max(hist_2016_sum, 1));
            double bin_2020 = static_cast<double>(hist_2020[i]);///(std::max(hist_2020_sum, 1));

            //double thres = 0.01;
            //if(bin_2016 < thres) bin_2016 = 0;
            //if(bin_2020 < thres) bin_2020 = 0;

            channel_diff[color_channel] += std::abs(bin_2016 - bin_2020);
        }
    }
    return channel_diff[0];// + channel_diff[1] + channel_diff[2]; //This seems dumb but that's what the internet says
    //return pow( channel_diff[0]*channel_diff[0]  + channel_diff[1]*channel_diff[1] + channel_diff[2]*channel_diff[2] ,0.5); //This seems dumb but that's what the internet says
}


double calculateGASHistogramDistance(float * hist_2016, float * hist_2020){
    float dist = 0;
    for(int i = 0 ; i < 7992; i++){
        auto bin_2016 = hist_2016[i];
        auto bin_2020 = hist_2020[i];
        dist += std::abs(bin_2016 - bin_2020 );
    }
    return dist;
}

void save_colors_of_pcl(const PointCloud3D::Ptr & pcl, const std::string filename){
    std::ofstream pcl_file;
    pcl_file.open(filename + ".csv");

    if(!pcl_file.is_open()) throw std::runtime_error("Could not open file");

    for(int i = 0; i < pcl->points.size(); i++){
        pcl_file << (int)pcl->points[i].r << ","<< (int)pcl->points[i].g << ","<< (int)pcl->points[i].b << '\n';
    }
    pcl_file.close();
}
void save_histogram(const std::vector<histogram>& hist, const std::string& filename){
    std::cout << "Saved Histograms" << std::endl;
    std::ofstream hist_file;
    hist_file.open(filename + ".csv");
    if(!hist_file.is_open()) throw std::runtime_error("Could not open file");

    for(int i = 0 ; i < hist[0].size(); i++){
        for(int j = 0; j<hist.size() ;j++){
            hist_file << (int)hist[j][i] << ",";
        }
        hist_file.seekp(hist_file.tellp() - (streamoff)1);
        hist_file << '\n';
    }
    hist_file.close();
}

template<typename T>
void parseColumnFile(const std::string& filename, std::vector<T>& data ){
    std::ifstream ifs;
    ifs.open(filename, std::ios::in);
    if(!ifs.is_open()) throw std::runtime_error("Could not open file!");

    std::string line;
    while(true) {
        if (!getline(ifs, line)) break;
        istringstream ss(line);
        if constexpr (std::is_same_v<T, int>) {
            data.push_back(std::stoi(line));
        }
        else {
            data.push_back(line);
        }
    }
}

void GASD(PointCloud3D::Ptr & cloud, pcl::PointCloud<pcl::GASDSignature7992>& descriptor) {
    for(int i = 0 ; i < cloud->size() ; i++){
        RGBtoHSV(cloud->points[i],cloud->points[i]);
    }

    // Create the GASD estimation class, and pass the input dataset to it
    pcl::GASDColorEstimation<pcl::PointXYZRGB, pcl::GASDSignature7992> gasd;
    gasd.setInputCloud(cloud);

    // Compute the descriptor
    gasd.compute(descriptor);

    // Unpack histogram bins
    for (std::size_t i = 0; i < std::size_t(descriptor[0].descriptorSize()); ++i) {
        descriptor[0].histogram[i];
    }
}


void SHOTEstimator(PointCloud3D::Ptr & cloud, pcl::PointCloud<pcl::SHOT1344>& descriptor){
    pcl::SHOTEstimation<pcl::PointXYZRGB,pcl::Normal,pcl::SHOT1344> shot_est;
    shot_est.setSearchMethod(pcl::search::KdTree<Point3D>::Ptr (new pcl::search::KdTree<Point3D>));
    shot_est.setRadiusSearch(10.0f);
    shot_est.setInputCloud(cloud);
    shot_est.setSearchSurface(cloud);
    shot_est.compute(descriptor);
}

void parseIniFile(const std::string& filename, std::string & out_dir){
    std::ifstream ifs;
    ifs.open(filename, std::ios::in);
    if(!ifs.is_open()) throw std::runtime_error("Could not open file!");

    std::string line;
    while(true) {
        if (!getline(ifs, line)) break;
        auto end = line.find("=");
        auto keyword = line.substr(0, end - 1);
        if(keyword == "out_dir")
            out_dir = line.substr(end+1,std::string::npos);
    }
    out_dir = out_dir.substr(1, out_dir.size() - 2);
}


int main (int argc, char **argv)
{
    std::vector<std::string> places = std::vector<std::string>();
    std::vector<std::string> models = std::vector<std::string>();
    std::vector<std::string> predicted = std::vector<std::string>();
    std::vector<std::string> my_predicted = std::vector<std::string>();
    std::vector<std::string> true_labels = std::vector<std::string>();
    std::vector<int> indeces = std::vector<int>();
    parseIniFile("../../ChangeDetectionDatasetViewer/config.ini", Dataset::out_dir);

    std::vector<std::string> scene_folders;
    list_folders(Dataset::out_dir +"/", scene_folders);

    if(argc > 1) {
        std::cout << "Converting LAS files to PLY" << std::endl;
        Dataset::just_save_files = true;
    }
    else {
        parseColumnFile("../../matlab_shrec/place.txt", places);
        parseColumnFile("../../matlab_shrec/model.txt", models);
        parseColumnFile("../../matlab_shrec/index.txt", indeces);
        parseColumnFile("../../matlab_shrec/predicted.txt", predicted);
        parseColumnFile("../../matlab_shrec/true.txt", true_labels);
    }

    std::map<std::string, std::vector<float>> label_distances={
            {"added", std::vector<float>()},
            {"removed", std::vector<float>()},
            {"nochange", std::vector<float>()},
            {"change", std::vector<float>()},
            {"color_change", std::vector<float>()}
    };

    std::string debug_scene_name = "36_5D4KX6T5";
    int debug_landmark_index = -1;
    bool save_pcl = false;

    //pcl::console::setVerbosityLevel(pcl::console::L_ALWAYS);
    std::vector<std::string> scene_filenames;
    if(Dataset::just_save_files)
        scene_filenames = scene_folders;
    else
        scene_filenames = places;
    int count = 0;
    for(auto & scene_name : scene_filenames) {
        Dataset dataset(scene_name);
        for (int i = 0; i < dataset.csv.labels.size(); i++) {
            if( (scene_name == debug_scene_name && debug_landmark_index == i) || debug_landmark_index == -1){
                dataset.load_landmarks(i);
                if(Dataset::just_save_files) continue;
                auto size_2016 = dataset.xyz_rgb_2016->size();
                auto size_2020 = dataset.xyz_rgb_2020->size();

                if(predicted[count] != "nochange" || std::max(size_2020, size_2016) > 2*std::min(size_2016, size_2020)) {
                    my_predicted.push_back(predicted[count]);
                    count++;
                    continue;
                }
                //removeGround(dataset.xyz_rgb_2016, dataset.csv.centers[i], 0.35f);
                //removeGround(dataset.xyz_rgb_2020, dataset.csv.centers[i], 0.35f);

                std::vector<histogram> hist_rgb_2016;
                std::vector<histogram> hist_rgb_2020;
                pcl::PointCloud<pcl::GASDSignature7992> descriptor_2016;
                pcl::PointCloud<pcl::GASDSignature7992> descriptor_2020;
                pcl::PointCloud<pcl::SHOT1344> shot_descriptor_2016;
                pcl::PointCloud<pcl::SHOT1344> shot_descriptor_2020;

                histogramRGB(dataset.xyz_rgb_2016, hist_rgb_2016);
                histogramRGB(dataset.xyz_rgb_2020, hist_rgb_2020);

                GASD(dataset.xyz_rgb_2016, descriptor_2016);
                GASD(dataset.xyz_rgb_2020, descriptor_2020);

                //SHOTEstimator(dataset.xyz_rgb_2016, shot_descriptor_2016);
                auto distance = calculateHistogramDistance(hist_rgb_2016, hist_rgb_2020);
                //auto distance = calculateGASHistogramDistance(descriptor_2016.points[0].histogram, descriptor_2020.points[0].histogram);

                label_distances[dataset.csv.labels[i]].push_back(distance);
                if(true_labels[count] == "color_change"){
                    std::cout << "Pointcloud sizes: " << dataset.xyz_rgb_2016->size() << " , " << dataset.xyz_rgb_2020->size() << std::endl;
                    std::cout << "Ratio:" << double(std::max(size_2020, size_2016)) / std::min(size_2016, size_2020) << std::endl;
                    std::cout << "The histogram difference is: " << distance
                              << " with label: " << dataset.csv.labels[i] << " Scene name: " << scene_name << " Index "
                              << i << std::endl;
                }
                if(dataset.csv.labels[i] == "added"){ //"color_change" || dataset.csv.labels[i] =="nochange") {
                    //std::cout << "Pointcloud sizes: " << dataset.xyz_rgb_2016->size() << " " << dataset.xyz_rgb_2020->size() << std::endl;
                    //std::cout << "The histogram difference is: " << distance
                    //          << " with label: " << dataset.csv.labels[i] << " Scene name: " << scene_name << " Index "
                    //          << i << std::endl;
                }
                if(distance > 9400 && distance < 53000){
                    my_predicted.emplace_back("color_change");
                }
                else{
                    my_predicted.emplace_back(predicted[count]);
                }
                count++;
                if(save_pcl){
                    save_colors_of_pcl(dataset.xyz_rgb_2016, std::string("../csv/2016_" + scene_name + "_" + std::to_string(i)));
                    save_colors_of_pcl(dataset.xyz_rgb_2020, std::string("../csv/2020_" + scene_name + "_" + std::to_string(i)));
                }
            }
        }
    }
    if(Dataset::just_save_files) return 0;
    ofstream myfile;
    myfile.open ("../../matlab_shrec/my_predicted.txt");
    for(int i = 0; i < my_predicted.size(); i++){
        myfile<<my_predicted[i] << "\n";
    }
    myfile.close();

    if(debug_landmark_index == -1) {
        //Saving results to csv files TODO make one unified csv file
        for (auto &dict_pair : label_distances) {
            std::ofstream results;
            results.open("../" + dict_pair.first + ".csv");
            if (!results.is_open()) throw std::runtime_error("Could not open file");
            for (int i = 0; i < dict_pair.second.size() - 1; i++) {
                results << std::to_string(dict_pair.second[i]) + '\n';
            }
            results << std::to_string(dict_pair.second[dict_pair.second.size() - 1]);
            results.close();
        }
    }
    return (0);
}