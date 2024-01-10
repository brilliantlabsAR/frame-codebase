onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /camera_pipeline_tb/global_reset_n
add wave -noupdate /camera_pipeline_tb/reset_n
add wave -noupdate /camera_pipeline_tb/clock_camera_pixel
add wave -noupdate /camera_pipeline_tb/reset_camera_pixel_n
add wave -noupdate /camera_pipeline_tb/clock_camera_byte
add wave -noupdate /camera_pipeline_tb/reset_camera_byte_n
add wave -noupdate /camera_pipeline_tb/clock_camera_sync
add wave -noupdate /camera_pipeline_tb/reset_camera_sync_n
add wave -noupdate /camera_pipeline_tb/pll_dphy_locked
add wave -noupdate -divider <NULL>
add wave -noupdate /camera_pipeline_tb/mipi_clock_p
add wave -noupdate /camera_pipeline_tb/mipi_clock_n
add wave -noupdate /camera_pipeline_tb/mipi_data_p
add wave -noupdate /camera_pipeline_tb/mipi_data_n
add wave -noupdate /camera_pipeline_tb/camera/byte_to_pixel_ip/payload_en_i
add wave -noupdate /camera_pipeline_tb/camera/byte_to_pixel_ip/payload_i
add wave -noupdate -divider <NULL>
add wave -noupdate /camera_pipeline_tb/camera/debayer/reset_n
add wave -noupdate /camera_pipeline_tb/camera/debayer/pixel_data
add wave -noupdate /camera_pipeline_tb/camera/debayer/line_valid
add wave -noupdate /camera_pipeline_tb/camera/debayer/frame_valid
add wave -noupdate /camera_pipeline_tb/camera/debayer/rgb10
add wave -noupdate /camera_pipeline_tb/camera/debayer/rgb8
add wave -noupdate /camera_pipeline_tb/camera/debayer/gray4
add wave -noupdate -divider <NULL>
add wave -noupdate /camera_pipeline_tb/camera/fifo/reset_n
add wave -noupdate /camera_pipeline_tb/camera/fifo/head
add wave -noupdate /camera_pipeline_tb/camera/fifo/write_enable_frame_buffer
add wave -noupdate /camera_pipeline_tb/camera/fifo/pixel_data_to_ram
add wave -noupdate /camera_pipeline_tb/camera/fifo/ram_address
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {114806150370 fs} 0}
quietly wave cursor active 1
configure wave -namecolwidth 264
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits fs
update
WaveRestoreZoom {0 fs} {921470417450 fs}
