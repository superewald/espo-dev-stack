<?php
include __DIR__.'/bootstrap.php';

if(count($argv) <= 2) {
    print("Please specify upload path to extension.\n");
    return;
}

$cmd = strtolower($argv[1]);
$path = $argv[2];

$app = new \Espo\Core\Application();
$app->setupSystemUser();
$container = $app->getContainer();

function runInstallScript(string $name, string $path, Espo\Core\Application $app) {
    $scriptPath = $path."/".$name.".php";
    if($app->getContainer()->get('fileManager')->exists($scriptPath)) {
        include($scriptPath);
        $scriptCls = new $name();
        $scriptCls->run($app->getContainer());
    }
}

function installExtension(string $path, \Espo\Core\Application $app) {
    try  {
        $container = $app->getContainer();

        /** @var Espo\Core\Utils\File\Manager */
        $fm = $container->get('fileManager');
        /** @var Espo\ORM\EntityManager */
        $em = $container->get('entityManager');
    
        if(!$fm->isDir($path)) {
            print("Path does not exist or is not directory!\n");
            return;
        }
        
        $config = $fm->getContents($path."/manifest.json");
        if(!$config) {
            print("Error: extension ".$path." is missing manifest.json");
            return;
        }
        $config = json_decode($config, true);

        $scriptPath = $path."/scripts";
        if(!is_dir($scriptPath) && is_dir($path."/src/scripts"))
            $scriptPath = $path."/src/scripts";

        // before install
        runInstallScript("BeforeInstall", $scriptPath, $app);
    
        // check if extension was already installed before
        $ext = $em->getRepository('Extension')->where([
            'name=' => $config['name']
        ])->findOne();
        
        
        if($ext == null) {
            $ext = $em->createEntity('Extension', $config);
            $ext->set('isInstalled', true);
            $em->saveEntity($ext);
    
            runInstallScript("AfterInstall", $scriptPath, $app);
    
            print("Extension {$config['name']} was installed.\n");
        } else {
            if(!$ext->get('isInstalled')) {
                $ext->set('isInstalled', true);
                $em->saveEntity($ext);
                print("Extension was activated.\n");
            }
    
            print("Extension {$config['name']} was already installed.\n");
        }
    } catch(Throwable $e) {
        print($e->getMessage());
        exit;
    }
}

function uninstallExtension(string $path, \Espo\Core\Application $app) {
    try  {
        $container = $app->getContainer();

        /** @var Espo\Core\Utils\File\Manager */
        $fm = $container->get('fileManager');
        /** @var Espo\ORM\EntityManager */
        $em = $container->get('entityManager');
    
        if(!$fm->isDir($path)) {
            print("Path does not exist or is not directory!");
            return;
        }
        
        $config = $fm->getContents($path."/manifest.json");
        if(!$config) {
            print("Error: extension ".$path." is missing manifest.json");
            return;
        }
        $config = json_decode($config, true);

        $scriptPath = $path."/scripts";
        if(!is_dir($scriptPath) && is_dir($path."/src/scripts"))
            $scriptPath = $path."/src/scripts";

        runInstallScript("BeforeUninstall", $scriptPath, $app);

        $exts = $em->getRepository('Extension')->where([
            'name' => $config['name']
        ])->find();

        foreach($exts as $ext) {
            $em->removeEntity($ext);
        }

        runInstallScript("AfterUninstall", $scriptPath, $app);
        print("Extension {$config['name']} was uninstalled.\n");
    } catch(Exception $e) {
        print($e->getMessage()."\n");
        return;
    }
}

switch($cmd) {
    case 'install':
    case 'i':
        installExtension($path, $app);
        break;
    case 'uninstall':
    case 'u':
        uninstallExtension($path, $app);
}