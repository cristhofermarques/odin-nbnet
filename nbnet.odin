package nbnet

import "core:mem"
import "core:log"
import "core:runtime"
import "core:c/libc"
import "core:fmt"

LOG :: #config(NBNET_LOG, false)

Connection_Handle :: u32

Connection_Debug_Callback :: enum i32
{
    Cb_Msg_Added_To_Recv_Queue,
}

// Connection_Vector :: struct
// {
//     connections: ^[^]Connection,
//     count,
//     capacity: u32,
// }

// Connection_Table :: struct
// {
//     connections: ^[^]Connection,
//     count,
//     capacity: u32,
//     load_factor: f32,
// }

// DEBUG :: #config(NBN_DEBUG, false)
// USE_PACKET_SIMULATOR :: #config(NBN_USE_PACKET_SIMULATOR, false)

// when DEBUG && USE_PACKET_SIMULATOR
// {
//     Mem :: enum i32
//     {
//         Message_Chunk,
//         Byte_Array_Message,
//         Connection,
//         Packet_Simulator_Entry,
//     }
// }
// else
// {
//     Mem :: enum i32
//     {
//         Message_Chunk,
//         Byte_Array_Message,
//         Connection,
//     }
// }

// Mem_Pool_Free_Block :: struct
// {
//     next: ^Mem_Pool_Free_Block,
// }

// Mem_Pool :: struct
// {
//     blocks: ^[^]u8,
//     block_size: u64,
//     block_count,
//     block_idx: u32,
//     free: ^Mem_Pool_Free_Block,
// }

// DISABLE_MEMORY_POOLING :: #config(NBN_DISABLE_MEMORY_POOLING, false)

// when DISABLE_MEMORY_POOLING
// {
//     Memory_Manager :: struct
//     {
//         mem_sizes: [16]u64,
//     }
// }
// else
// {
//     Memory_Manager :: struct
//     {
//         mem_pools: [16]Mem_Pool,
//     }
// }

// Word :: u32

// Bit_Reader :: struct
// {
//     size: u32,
//     buffer: ^u8,
//     scratch: u64,
//     scratch_bits_count,
//     byte_cursor: u32,
// }

// Bit_Writer :: struct
// {
//     size: u32,
//     buffer: ^u8,
//     scratch: u64,
//     scratch_bits_count,
//     byte_cursor: u32,
// }

Stream_Serialize_UInt :: #type proc "c" (^Stream, ^u32, u32, u32) -> i32
Stream_Serialize_UInt64 :: #type proc "c" (^Stream, ^u64) -> i32
Stream_Serialize_Int :: #type proc "c" (^Stream, ^i32, i32, i32) -> i32
Stream_Serialize_Float :: #type proc "c" (^Stream, ^f32, f32, f32, int) -> i32
Stream_Serialize_Bool :: #type proc "c" (^Stream, ^bool) -> i32
Stream_Serialize_Padding :: #type proc "c" (^Stream) -> i32
Stream_Serialize_Bytes :: #type proc "c" (^Stream, rawptr, u32) -> i32

Message_Serializer :: #type proc "c" (rawptr, ^Stream) -> i32
Message_Builder :: #type proc "c" () -> rawptr
Message_Destructor :: #type proc "c" (rawptr)

Stream_Type :: enum i32
{
    Write,
    Read,
    Measure,
}

Stream :: struct
{
    type: Stream_Type,
    serialize_uint_func: Stream_Serialize_UInt,
    serialize_uint64_func: Stream_Serialize_UInt64,
    serialize_int_func: Stream_Serialize_Int,
    serialize_float_func: Stream_Serialize_Float,
    serialize_bool_func: Stream_Serialize_Bool,
    serialize_padding_func: Stream_Serialize_Padding,
    serialize_bytes_func: Stream_Serialize_Bytes,
};

// Read_Stream :: struct
// {
//     base: Stream,
//     bit_reader: Bit_Reader,
// }

// Write_Stream :: struct
// {
//     base: Stream,
//     bit_writer: Bit_Writer,
// }

// Measure_Stream :: struct
// {
//     NBN_Stream base;
//     unsigned int number_of_bits;
// } NBN_MeasureStream;]

Connection_Stats :: struct
{
    ping: f64,
    total_lost_packets: u32,
    packet_loss,
    upload_bandwidth,
    download_bandwidth: f32,
}

/*
Information about a received message.
*/
Message_Info :: struct
{
    /* User defined message's type */
    type,

    /** Channel the message was received on */
    channel_id: u8,

    /** Message's data */
    data: rawptr,

    /**
    * The message's sender.
    * 
    * On the client side, it will always be 0 (all received messages come from the game server).
    */
    sender: Connection_Handle,
}


/* No event left in the events queue */
NO_EVENT :: 0

/* Indicates that the event should be skipped */
SKIP_EVENT :: 1

/* Client is connected to server */
CONNECTED :: 2

/* Client is disconnected from the server */
DISCONNECTED :: 3

/* Client has received a message from the server */
MESSAGE_RECEIVED :: 4

Game_Server_Stats :: struct
{
    /* Total upload bandwith of the game server */
    upload_bandwidth,

    /* Total download bandwith of the game server */
    download_bandwidth: f32,
}

// The context used by nbnet
_context: runtime.Context

@(export, link_name="_NBN_Allocator")
_nbn_allocator :: proc "c" (size: u64) -> rawptr
{
    context = _context
    fmt.println("Allocate")
    buf, _ := mem.alloc(int(size), mem.DEFAULT_ALIGNMENT, context.allocator)
    return buf
}

@(export, link_name="_NBN_Reallocator")
_nbn_reallocator :: proc "c" (data: rawptr, size: u64) -> rawptr
{
    context = _context
    fmt.println("Reallocate")
    buf, _ := mem.resize(data, 1, int(size), mem.DEFAULT_ALIGNMENT, context.allocator)
    return buf
}

@(export, link_name="_NBN_Deallocator")
_nbn_deallocator :: proc "c" (data: rawptr)
{
    context = _context
    fmt.println("Free")
    mem.free(data, context.allocator)
}

@(export, link_name="_NBN_LogTrace")
_nbn_log_trace :: proc "c" (text: cstring)
{
    context = _context
    log.debug(cast(string)text)
}

@(export, link_name="_NBN_LogDebug")
_nbn_log_debug :: proc "c" (text: cstring)
{
    context = _context
    log.debug(cast(string)text)
}

@(export, link_name="_NBN_LogInfo")
_nbn_log_info :: proc "c" (text: cstring)
{
    context = _context
    log.info(cast(string)text)
}

@(export, link_name="_NBN_LogWarning")
_nbn_log_warning :: proc "c" (text: cstring)
{
    context = _context
    log.warn(cast(string)text)
}

@(export, link_name="_NBN_LogError")
_nbn_log_error :: proc "c" (text: cstring)
{
    context = _context
    log.error(cast(string)text)
}

when ODIN_OS == .Windows && ODIN_ARCH == .amd64
{
    when LOG
    {
        foreign import nbnet {
            "binaries/nbnet_windows_amd64_log.lib",
            "system:ws2_32.lib",
        }
    }
    else
    {
        foreign import nbnet {
            "binaries/nbnet_windows_amd64.lib",
            "system:ws2_32.lib",
        }
    }
}

@(default_calling_convention="c")
foreign nbnet
{
    when LOG
    {
        @(link_name="NBN_Log_Allocate_Buffer")
        log_allocate_buffer :: proc(length: u64 = 1024) -> bool ---
        
        @(link_name="NBN_Log_Free_Buffer")
        log_free_buffer :: proc() ---
    }

    @(link_name="NBN_UDP_Register")
    udp_register :: proc() ---

    // @(link_name="NBN_BitReader_Init")
    // bit_reader_init :: proc(^Bit_Reader, ^u8, i32) ---

    // @(link_name="NBN_BitReader_Read")
    // bit_reader_read :: proc(^Bit_Reader, ^Word, i32) -> i32 ---


    // @(link_name="NBN_BitWriter_Init")
    // bit_writer_init :: proc(^Bit_Writer, ^u8, u32) ---

    // @(link_name="NBN_BitWriter_Write")
    // bit_writer_write :: proc(^Bit_Writer, Word, i32) -> i32 ---

    // @(link_name="NBN_BitWriter_Flush")
    // bit_writer_flush :: proc(^Bit_Writer) -> i32 ---


    // @(link_name="NBN_ReadStream_Init")
    // read_stream_init :: proc(^Read_Stream, ^u8, u32) ---

    // @(link_name="NBN_ReadStream_SerializeUint")
    // read_stream_serialize_u32 :: proc(^Read_Stream, ^u32, u32, u32) -> i32 ---

    // @(link_name="NBN_ReadStream_SerializeUint64")
    // read_stream_serialize_u64 :: proc(read_stream: ^Read_Stream, value: ^u64) -> i32 ---

    // @(link_name="NBN_ReadStream_SerializeInt")
    // read_stream_serialize_i32 :: proc(^Read_Stream, ^i32, i32, i32) -> i32 ---

    // @(link_name="NBN_ReadStream_SerializeFloat")
    // read_stream_serialize_f32 :: proc(^Read_Stream, ^f32, f32, f32, int) -> i32 ---

    // @(link_name="NBN_ReadStream_SerializeBool")
    // read_stream_serialize_bool :: proc(^Read_Stream, ^bool) -> i32 ---

    // @(link_name="NBN_ReadStream_SerializePadding")
    // read_stream_serialize_padding :: proc(^Read_Stream) -> i32 ---

    // @(link_name="NBN_ReadStream_SerializeBytes")
    // read_stream_serialize_bytes :: proc(^Read_Stream, [^]u8, u32) -> i32 ---


    // @(link_name="NBN_WriteStream_Init")
    // write_stream_init :: proc(^Write_Stream, [^]u8, u32) ---

    // @(link_name="NBN_WriteStream_SerializeUint")
    // write_stream_serialize_u32 :: proc(^Write_Stream, ^u32, u32, u32) -> i32 ---

    // @(link_name="NBN_WriteStream_SerializeUint64")
    // write_stream_serialize_u64 :: proc(write_stream: ^Write_Stream, value: ^u64) -> i32 ---

    // @(link_name="NBN_WriteStream_SerializeInt")
    // write_stream_serialize_i32 :: proc(^Write_Stream, ^i32, i32, i32) -> i32 ---

    // @(link_name="NBN_WriteStream_SerializeFloat")
    // write_stream_serialize_f32 :: proc(^Write_Stream, ^f32, f32, f32, i32) -> i32 ---

    // @(link_name="NBN_WriteStream_SerializeBool")
    // write_stream_serialize_bool :: proc(^Write_Stream, ^bool) -> i32 ---

    // @(link_name="NBN_WriteStream_SerializePadding")
    // write_stream_serialize_padding :: proc(^Write_Stream) -> i32 ---

    // @(link_name="NBN_WriteStream_SerializeBytes")
    // write_stream_serialize_bytes :: proc(^Write_Stream, [^]u8, u32) -> i32 ---

    // @(link_name="NBN_WriteStream_Flush")
    // write_stream_flush :: proc(^Write_Stream) -> i32 ---


    /**
    * Start the game client and send a connection request to the server.
    *
    * @param protocol_name A unique protocol name, the clients and the server must use the same one or they won't be able to communicate
    * @param host Host to connect to
    * @param port Port to connect to
    *
    * @return 0 when successully started, -1 otherwise
    */
    @(link_name="NBN_GameClient_Start")
    game_client_start :: proc(protocol_name, host: cstring, port: u16) -> i32 ---

    /**
    * Same as NBN_GameClient_Start but with additional parameters. 
    *
    * param 'protocol_name' A unique protocol name, the clients and the server must use the same one or they won't be able to communicate
    * param 'host' Host to connect to
    * param 'port' Port to connect to
    * param 'enable_encryption' Enable or disable packet encryption
    * param 'data' Array of bytes to send to the server upon connection (cannot exceed NBN_CONNECTION_DATA_MAX_SIZE)
    * param 'length' length of the array of bytes
    *
    * return 0 when successully started, -1 otherwise
    */
    @(link_name="NBN_GameClient_StartEx")
    game_client_start_ex :: proc(protocol_name, host: cstring, port: u16, enable_encryption: bool, data: [^]u8, length: u32) -> i32 ---
    
    /**
    * Disconnect from the server. The client can be restarted by calling NBN_GameClient_Start or NBN_GameClient_StartWithData again.
    */
    @(link_name="NBN_GameClient_Stop")
    game_client_stop :: proc() ---

    /**
    * Read the server data that was received upon connection into a preallocated buffer (the buffer must have a size of at least NBN_SERVER_DATA_MAX_SIZE bytes).
    *
    * @param data The target buffer to copy the server data to
    *
    * @return the length of the server data in bytes
    */
    @(link_name="NBN_GameClient_ReadServerData")
    game_client_read_server_data :: proc (data: ^u8) -> u32 ---

    /**
    * Register a type of message on the game client, has to be called after NBN_GameClient_Start.
    * 
    * 
    * @param msg_type A user defined message type, can be any value from 0 to 245 (245 to 255 are reserved by nbnet).
    * @param msg_builder The function responsible for building the message
    * @param msg_destructor The function responsible for destroying the message (and releasing memory)
    * @param msg_serializer The function responsible for serializing the message
    */
    @(link_name="NBN_GameClient_RegisterMessage")
    game_client_register_message :: proc(msg_type: u8, msg_builder: Message_Builder, msg_destructor: Message_Destructor, msg_serializer: Message_Serializer) ---

    /**
    * Poll game client events.
    * 
    * This function should be called in a loop until it returns NBN_NO_EVENT.
    * 
    * @return The code of the polled event or NBN_NO_EVENT when there is no more events.
    */
    @(link_name="NBN_GameClient_Poll")
    game_client_poll :: proc() -> i32 ---

    /**
    * Pack all enqueued messages into packets and send them.
    * 
    * This should be called at a relatively high frequency, probably at the end of
    * every game tick.
    * 
    * @return 0 when successful, -1 otherwise
    */
    @(link_name="NBN_GameClient_SendPackets")
    game_client_send_packets :: proc() -> i32 ---

    /**
    * Send a byte array message on a given channel.
    *
    * It's recommended to use NBN_GameClient_SendUnreliableByteArray or NBN_GameClient_SendReliableByteArray
    * unless you really want to use a specific channel.
    * 
    * @param bytes The byte array to send
    * @param length The length of the byte array to send
    * @param channel_id The ID of the channel to send the message on
    * 
    * @return 0 when successful, -1 otherwise
    */
    @(link_name="NBN_GameClient_SendByteArray")
    game_client_send_byte_array :: proc(bytes: [^]byte, length: u32, channel_id: u8) -> i32 ---

    /**
    * Send a message to the server on a given channel.
    * 
    * It's recommended to use NBN_GameClient_SendUnreliableMessage or NBN_GameClient_SendReliableMessage
    * unless you really want to use a specific channel.
    * 
    * @param msg_type The type of message to send; it needs to be registered (see NBN_GameClient_RegisterMessage)
    * @param channel_id The ID of the channel to send the message on
    * @param msg_data A pointer to the message to send (managed by user code)
    * 
    * @return 0 when successful, -1 otherwise
    */
    @(link_name="NBN_GameClient_SendMessage")
    game_client_send_message :: proc(msg_type, channel_id: u8, msg_data: rawptr) -> i32 ---

    /**
    * Send a message to the server, unreliably.
    * 
    * @param msg_type The type of message to send; it needs to be registered (see NBN_GameClient_RegisterMessage)
    * @param msg_data A pointer to the message to send (managed by user code)
    * 
    * @return 0 when successful, -1 otherwise
    */
    @(link_name="NBN_GameClient_SendUnreliableMessage")
    game_client_send_unreliable_message :: proc(msg_type: u8, msg_data: rawptr) -> i32 ---

    /**
    * Send a message to the server, reliably.
    *
    * @param msg_type The type of message to send; it needs to be registered (see NBN_GameClient_RegisterMessage)
    * @param msg_data A pointer to the message to send (pointing to user code memory)
    *
    * @return 0 when successful, -1 otherwise
    */
    @(link_name="NBN_GameClient_SendReliableMessage")
    game_client_send_reliable_message :: proc(msg_type: u8, msg_data: rawptr) -> i32 ---

    /*
    * Send a byte array to the server, unreliably.
    *
    * @param bytes The byte array to send
    * @param length The length of the byte array to send
    *
    * @return 0 when successful, -1 otherwise
    */
    @(link_name="NBN_GameClient_SendUnreliableByteArray")
    game_client_send_unreliable_byte_array :: proc(bytes: [^]byte, length: u32) -> i32 ---

    /*
    * Send a byte array to the server, reliably.
    * 
    * @param bytes The byte array to send
    * @param length The length of the byte array to send
    * 
    * @return 0 when successful, -1 otherwise
    */
    @(link_name="NBN_GameClient_SendReliableByteArray")
    game_client_send_reliable_byte_array :: proc(bytes: [^]byte, length: u32) -> i32 ---

    /**
    * Retrieve the info about the last received message.
    * 
    * Call this function when receiveing a NBN_MESSAGE_RECEIVED event to access
    * information about the message.
    * 
    * @return A structure containing information about the received message
    */
    @(link_name="NBN_GameClient_GetMessageInfo")
    game_client_get_message_info :: proc() -> Message_Info ---

    /**
    * Retrieve network stats about the game client.
    * 
    * @return A structure containing network related stats about the game client
    */
    @(link_name="NBN_GameClient_GetStats")
    game_client_get_stats :: proc() -> Connection_Stats ---

    /**
    * Retrieve the code sent by the server when closing the connection.
    * 
    * Call this function when receiving a NBN_DISCONNECTED event.
    * 
    * @return The code used by the server when closing the connection or -1 (the default code)
    */
    @(link_name="NBN_GameClient_GetServerCloseCode")
    game_client_get_server_close_code :: proc() -> i32 ---

    /**
    * @return true if connected, false otherwise
    */
    @(link_name="NBN_GameClient_IsConnected")
    game_client_is_connected :: proc() -> bool ---

    when ODIN_DEBUG
    {
        @(link_name="NBN_GameClient_Debug_RegisterCallback")
        game_client_debug_register_callback :: proc(Connection_Debug_Callback, rawptr) ---
    }

    /**
    * Start the game server.
    * 
    * @param protocol_name A unique protocol name, the clients and the server must use the same one or they won't be able to communicate
    * @param port The server's port
    *
    * @return 0 when successfully started, -1 otherwise
    */
    @(link_name="NBN_GameServer_Start")
    game_server_start :: proc(protocol_name: cstring, port: u16) -> i32 ---

    /**
    * Same as NBN_GameServer_Start but with additional parameters.
    *
    * @param protocol_name A unique protocol name, the clients and the server must use the same one or they won't be able to communicate
    * @param port The server's port
    * @param enable_encryption Enable or disable packet encryption
    *
    * @return 0 when successfully started, -1 otherwise
    */
    @(link_name="NBN_GameServer_StartEx")
    game_server_start_ex :: proc(protocol_name: cstring, port: u16, enable_encryption: bool) -> i32 ---

    /**
    * Stop the game server and clean everything up.
    */
    @(link_name="NBN_GameServer_Stop")
    game_server_stop :: proc() ---

    /**
    * Register a type of message on the game server, has to be called after NBN_GameServer_Start.
    * 
    * 
    * @param msg_type A user defined message type, can be any value from 0 to 245 (245 to 255 are reserved by nbnet).
    * @param msg_builder The function responsible for building the message
    * @param msg_destructor The function responsible for destroying the message (and releasing memory)
    * @param msg_serializer The function responsible for serializing the message
    */
    @(link_name="NBN_GameServer_RegisterMessage")
    game_server_register_message :: proc(msg_type: u8, msg_builder: Message_Builder, msg_destructor: Message_Destructor, msg_serializer: Message_Serializer) ---

    /**
    * Poll game server events.
    *
    * This function should be called in a loop until it returns NBN_NO_EVENT.
    *
    * @return The code of the polled event or NBN_NO_EVENT when there is no more events.
    */
    @(link_name="NBN_GameServer_Poll")
    game_server_poll :: proc() -> i32 ---

    /**
    * Pack all enqueued messages into packets and send them.
    * 
    * This should be called at a relatively high frequency, probably at the end of
    * every game tick.
    * 
    * @return 0 when successful, -1 otherwise
    */
    @(link_name="NBN_GameServer_SendPackets")
    game_server_send_packets :: proc() -> i32 ---

    /**
    * Close a client's connection without a specific code (default code is -1)
    *
    * @param connection_handle The connection to close
    * 
    * @return 0 when successful, -1 otherwise
    */
    @(link_name="NBN_GameServer_CloseClient")
    game_server_close_client :: proc(connection_handle: Connection_Handle) -> i32 ---

    /**
    * Close a client's connection with a specific code.
    * 
    * The code is an arbitrary integer to let the client knows
    * why his connection was closed.
    *
    * @param connection_handle The connection to close
    * 
    * @return 0 when successful, -1 otherwise
    */
    @(link_name="NBN_GameServer_CloseClientWithCode")
    game_server_close_client_with_code :: proc(connection_handle: Connection_Handle, code: i32) -> i32 ---

    /**
    * Send a byte array to a client on a given channel.
    * 
    * @param connection_handle The connection to send the message to
    * @param bytes The byte array to send
    * @param length The length of the byte array to send
    * @param channel_id The ID of the channel to send the message on
    * 
    * @return 0 when successful, -1 otherwise
    */
    @(link_name="NBN_GameServer_SendByteArrayTo")
    game_server_send_byte_array_to :: proc(connection_handle: Connection_Handle, bytes: [^]byte, length: u32, channel_id: u8) -> i32 ---

    /**
    * Send a message to a client on a given channel.
    *
    * It's recommended to use NBN_GameServer_SendUnreliableMessageTo or NBN_GameServer_SendReliableMessageTo
    * unless you really want to use a specific channel.
    *
    * @param connection_handle The connection to send the message to
    * @param msg_type The type of message to send; it needs to be registered (see NBN_GameServer_RegisterMessage)
    * @param channel_id The ID of the channel to send the message on
    * @param msg_data A pointer to the message to send
    *
    * @return 0 when successful, -1 otherwise
    */
    @(link_name="NBN_GameServer_SendMessageTo")
    game_server_send_message_to :: proc(connection_handle: Connection_Handle, msg_type, channel_id: u8, msg_data: rawptr) -> i32 ---

    /**
    * Send a message to a client, unreliably.
    *
    * @param connection_handle The connection to send the message to
    * @param msg_type The type of message to send; it needs to be registered (see NBN_GameServer_RegisterMessage)
    * @param msg_data A pointer to the message to send (managed by user code)
    *
    * @return 0 when successful, -1 otherwise
    */
    @(link_name="NBN_GameServer_SendUnreliableMessageTo")
    game_server_send_unreliable_message_to :: proc(connection_handle: Connection_Handle, msg_type: u8, msg_data: rawptr) -> i32 ---

    /**
    * Send a message to a client, reliably.
    *
    * @param connection_handle The connection to send the message to
    * @param msg_type The type of message to send; it needs to be registered (see NBN_GameServer_RegisterMessage)
    * @param msg_data A pointer to the message to send (managed by user code)
    *
    * @return 0 when successful, -1 otherwise
    */
    @(link_name="NBN_GameServer_SendReliableMessageTo")
    game_server_send_reliable_message_to :: proc(connection_handle: Connection_Handle, msg_type: u8, msg_data: rawptr) -> i32 ---

    /**
    * Send a byte array to a client, unreliably.
    *
    * @param connection_handle The connection to send the message to
    * @param bytes The byte array to send
    * @param length The length of the byte array to send
    *
    * @return 0 when successful, -1 otherwise
    */
    @(link_name="NBN_GameServer_SendUnreliableByteArrayTo")
    game_server_send_unreliable_byte_array_to :: proc(connection_handle: Connection_Handle, bytes: [^]byte, length: u32) -> i32 ---

    /**
    * Send a byte array to a client, reliably.
    * 
    * @param connection_handle The connection to send the message to
    * @param bytes The byte array to send
    * @param length The length of the byte array to send
    * 
    * @return 0 when successful, -1 otherwise
    */
    @(link_name="NBN_GameServer_SendReliableByteArrayTo")
    game_server_send_reliable_byte_array_to :: proc(connection_handle: Connection_Handle, bytes: [^]byte, length: u32) -> i32 ---

    /**
    * Accept the last client connection request and send a blob of data to the client.
    * The client can read that data using the NBN_GameClient_ReadServerData function.
    * If you do not wish to send any data to the client upon accepting his connection, use the NBN_GameServer_AcceptIncomingConnection function instead.
    * 
    * Call this function after receiving a NBN_NEW_CONNECTION event.
    *
    * @param data Data to send
    * @param length Data length in bytes
    * 
    * @return 0 when successful, -1 otherwise
    */
    @(link_name="NBN_GameServer_AcceptIncomingConnectionWithData")
    game_server_accept_incoming_connection_with_data :: proc(data: [^]byte, length: u32) -> i32 ---

    /**
    * Accept the last client connection request.
    *
    * @return 0 when successful, -1 otherwise
    */
    @(link_name="NBN_GameServer_AcceptIncomingConnection")
    game_server_accept_incoming_connection :: proc() -> i32 ---

    /**
    * Reject the last client connection request with a specific code.
    * 
    * The code is an arbitrary integer to let the client knows why his connection
    * was rejected.
    * 
    * Call this function after receiving a NBN_NEW_CONNECTION event.
    * 
    * @return 0 when successful, -1 otherwise
    */
    @(link_name="NBN_GameServer_RejectIncomingConnectionWithCode")
    game_server_reject_incoming_connection_with_code :: proc(code: i32) -> i32 ---

    /**
    * Reject the last client connection request without any specific code (default code is -1)
    * 
    * Call this function after receiving a NBN_NEW_CONNECTION event.
    * 
    * @return 0 when successful, -1 otherwise
    */
    @(link_name="NBN_GameServer_RejectIncomingConnection")
    game_server_reject_incoming_connection :: proc() -> i32 ---

    /**
    * Retrieve the last connection to the game server.
    * 
    * Call this function after receiving a NBN_NEW_CONNECTION event.
    * 
    * @return A NBN_ConnectionHandle for the new connection
    */
    @(link_name="NBN_GameServer_GetIncomingConnection")
    game_server_get_incoming_connection :: proc() -> Connection_Handle ---

    /**
    * Read the last connection data into a preallocated buffer. The target buffer must have a length of at least NBN_CONNECTION_DATA_MAX_SIZE bytes.
    *
    * @param data the buffer to copy the connection data to
    *
    * @return the length in bytes of the connection data
    */
    @(link_name="NBN_GameServer_ReadIncomingConnectionData")
    game_server_read_incoming_connection_data :: proc(data: [^]byte) -> u32 ---

    /**
    * Return the last disconnected client.
    * 
    * Call this function after receiving a NBN_CLIENT_DISCONNECTED event.
    * 
    * @return The last disconnected connection
    */
    @(link_name="NBN_GameServer_GetDisconnectedClient")
    game_server_get_disconnected_client :: proc() -> Connection_Handle ---

    /**
    * Retrieve the info about the last received message.
    * 
    * Call this function when receiving a NBN_CLIENT_MESSAGE_RECEIVED event to access
    * information about the message.
    * 
    * @return A structure containing information about the received message
    */
    @(link_name="NBN_GameServer_GetMessageInfo")
    game_server_get_message_info :: proc() -> Message_Info ---

    /**
    * Retrieve network stats about the game server.
    * 
    * @return A structure containing network related stats about the game server
    */
    @(link_name="NBN_GameServer_GetStats")
    game_server_get_stats :: proc() -> Game_Server_Stats ---
}