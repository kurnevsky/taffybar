{-# LANGUAGE OverloadedStrings #-}
-----------------------------------------------------------------------------
-- |
-- Module      : System.Taffybar.Widget.SNITray
-- Copyright   : (c) Ivan A. Malison
-- License     : BSD3-style (see LICENSE)
--
-- Maintainer  : Ivan A. Malison
-- Stability   : unstable
-- Portability : unportable
-----------------------------------------------------------------------------
--
-- A widget to display the system tray.
--
-- This widget only supports the newer StatusNotifierItem (SNI) protocol;
-- older xembed applets will not be visible. AppIndicator is also a valid
-- implementation of SNI.
--
-- Additionally, it does not handle recognising new tray applets. Instead it is
-- necessary to run status-notifier-watcher from the
-- [status-notifier-item](https://github.com/taffybar/status-notifier-item)
-- package early on system startup.
-- In case this is not possiblle,
-- 'sniTrayThatStartsWatcherEvenThoughThisIsABadWayToDoIt is available, but
-- this may not necessarily be able to pick up everything.

module System.Taffybar.Widget.SNITray where

import           Control.Monad.Trans.Class
import           Control.Monad.Trans.Reader
import qualified GI.Gtk
import qualified StatusNotifier.Host.Service as H
import           StatusNotifier.Tray
import           System.Posix.Process
import           System.Taffybar.Context
import           System.Taffybar.Widget.Util
import           Text.Printf

getHost :: Bool -> TaffyIO H.Host
getHost startWatcher = getStateDefault $ do
  pid <- lift getProcessID
  client <- asks sessionDBusClient
  Just host <- lift $ H.build H.defaultParams
     { H.dbusClient = Just client
     , H.uniqueIdentifier = printf "taffybar-%s" $ show pid
     , H.startWatcher = startWatcher
     }
  return host

-- | Build a new StatusNotifierItem tray from the provided parameters
sniTrayNewFromParams :: TrayParams -> TaffyIO GI.Gtk.Widget
sniTrayNewFromParams params = getHost False >>= sniTrayNewFromHostParams params

sniTrayNewFromHostParams :: TrayParams -> H.Host -> TaffyIO GI.Gtk.Widget
sniTrayNewFromHostParams params host = do
  client <- asks sessionDBusClient
  lift $ do
    tray <- buildTray host client params
    _ <- widgetSetClassGI tray "sni-tray"
    GI.Gtk.widgetShowAll tray
    GI.Gtk.toWidget tray

-- | Build a new StatusNotifierItem tray that will share a host with any other
-- trays that are constructed automatically
sniTrayNew :: TaffyIO GI.Gtk.Widget
sniTrayNew = sniTrayNewFromParams defaultTrayParams

-- | Build a new StatusNotifierItem tray that also starts its own watcher,
-- without depending on status-notifier-icon. This will not register applets
-- started before the watcher is started.
sniTrayThatStartsWatcherEvenThoughThisIsABadWayToDoIt :: TaffyIO GI.Gtk.Widget
sniTrayThatStartsWatcherEvenThoughThisIsABadWayToDoIt =
  getHost True >>= sniTrayNewFromHostParams defaultTrayParams

