﻿using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;

namespace SimulatorApp
{
    class Program
    {
        const string ConnectionString = "Server=192.168.0.80;Database=eShopWithOrders;User Id=sa;Password=Pa$$w0rd;";

        static LoaderOptions _option = new LoaderOptions();
        static bool _exit = false;

        static void Main(string[] args)
        {
            args = new string[] { "-t", "40","-c", "5" };

            SetArgs(_option, args);

            List<Task> _tasks;

            _tasks = new List<Task>();

            for (int i = 0; i < _option.Task; i++)
                _tasks.Add(new Task(AddOrder));

            for (int i = 0; i < _option.Task; i++)
                _tasks[i].Start();

            //判斷是否已經完成模擬
            while (_exit == false)
            {
                _exit = true;

                for (int i = 0; i < _option.Task; i++)
                {
                    if (_tasks[i].Status == TaskStatus.Running
                        || _tasks[i].Status == TaskStatus.WaitingToRun)
                    {
                        Thread.Sleep(100);
                        _exit = false;
                        continue;
                    }
                }

                if (_exit == false)
                    continue;

                _exit = true;

                Thread.Sleep(1000);
            }

            Console.WriteLine("press any key to exit");
            Console.ReadKey();
        }

        static void AddOrder()
        {
            while(_option.Start == false)
            {
                Thread.Sleep(10);
            }

            using(SqlConnection _conn = new SqlConnection(ConnectionString))
            {
                SqlCommand _cmd = new SqlCommand();
                _cmd.Connection = _conn;
                _cmd.CommandType = CommandType.StoredProcedure;
                _cmd.CommandText = "Orders.AddOrder";
                _cmd.CommandTimeout = 10;

                _cmd.Parameters.Add("@IsSuccess", SqlDbType.Bit);
                _cmd.Parameters["@IsSuccess"].Direction = ParameterDirection.Output;

                var _count = _option.Count;
                var _isSuccess = false;
                var _exception = string.Empty;

                Stopwatch _stopwatch = new Stopwatch();

                for (int i = 0; i < _count; i++)
                {
                    _cmd.Parameters["@IsSuccess"].Value = DBNull.Value;

                    _stopwatch.Start();
                    _isSuccess = false; 

                    try
                    {

                        _conn.Open();
                        _cmd.ExecuteNonQuery();
                        _conn.Close();


                        var _returnValue = _cmd.Parameters["@IsSuccess"].Value;

                        _isSuccess = Convert.ToBoolean(_returnValue);

                    }
                    catch(Exception ex)
                    {
                        _exception = (JsonConvert.SerializeObject(ex, Formatting.Indented));
                    }

                    _stopwatch.Stop();

                    Console.WriteLine("add order\treturn:{0}\telapsed:{1}"
                                    , _isSuccess
                                    , _stopwatch.ElapsedMilliseconds);

                    if (string.IsNullOrWhiteSpace(_exception) == false)
                        Console.WriteLine(_exception);

                    _stopwatch.Reset();
                }
            }
        }

        static void SetArgs(LoaderOptions option, string[] args)
        {
            var _arg = string.Empty;
            var _index = 0;

            for (int i = 0; i < args.Length; i++)
            {
                _arg = args[i];
                _index = i + 1;

                if (_index <= args.Length)
                {
                    switch (_arg)
                    {
                        case "-t":
                            option.TaskNumber = args[_index];
                            break;
                        case "-c":
                            option.CountString = args[_index];
                            break;
                        default:
                            break;
                    }
                }
            }

            Console.WriteLine("-------------------------");
            Console.WriteLine("Task 資訊");
            Console.WriteLine("-------------------------");
            Console.WriteLine("起始時間:{0}\t總數:{1}\t執行次數:{2}"
                            , option.StartTime
                            , option.Task
                            , option.Count);

        }
    }
}
